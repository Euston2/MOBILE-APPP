package com.lockout.lockout.platform

import android.content.Context

/**
 * The one implementation of the midnight transition.
 *
 * Called from the alarm, from `BOOT_COMPLETED`/time-change receivers, from the
 * service start and from every poll. It is deliberately idempotent:
 * - finished days are archived at most once per local date
 *   (`last_archived_date`), including up to [ArchivePlanner.MAX_CATCH_UP_DAYS]
 *   missed days after a force-stop, reboot or long power-off;
 * - an expired lock is cleared only when `now >= next_reset_at`;
 * - a pending configuration is folded into the active one once due.
 *
 * Order matters. Archiving happens before the pending configuration is
 * materialised, and before the lock is cleared, because each archived day must
 * use the app set/limit that governed it and the lock timestamp is part of the
 * record. [BlockingConfig.effectiveAt] resolves the configuration at the end of
 * each missing day, so a pending change saved before that day's midnight is
 * applied to the right historical day.
 */
object MidnightReset {

    data class Result(
        val config: BlockingConfig,
        val archived: Boolean,
        val lockCleared: Boolean,
        val materialised: Boolean,
        val resetAdvanced: Boolean,
        val focusRolled: Boolean = false,
    ) {
        val changed: Boolean
            get() = archived ||
                lockCleared ||
                materialised ||
                resetAdvanced ||
                focusRolled
    }

    fun recover(
        context: Context,
        config: BlockingConfig = BlockingStore.load(context),
        nowMs: Long = System.currentTimeMillis(),
    ): Result {
        var current = config
        var archived = false

        // Recover every finished day that has no archive record yet. The
        // planner bounds the work to the most recent 14 missed days, so a device
        // that was off for months does not run a huge UsageStats query.
        val missingDays = ArchivePlanner.datesToArchive(
            lastArchivedDate = ArchiveStore.lastArchivedDate(context),
            nowMs = nowMs,
        )
        for (date in missingDays) {
            val dayStartMs = DayMath.parseLocalDate(date) ?: continue
            val dayEndMs = DayMath.nextLocalMidnight(dayStartMs)

            // "End of day minus one millisecond" is the configuration that
            // governed the day. A change effective at the next midnight belongs
            // to the next day.
            val dayConfig = current.effectiveAt(dayEndMs - 1L)
            val apps = if (dayConfig.packages.isEmpty()) {
                emptyMap()
            } else {
                runCatching {
                    BlockUsage.secondsByPackage(
                        context,
                        dayStartMs,
                        dayEndMs,
                        dayConfig.packages,
                    )
                }.onFailure { error ->
                    LockoutLog.warn(
                        context,
                        "usage query failed for $date: " +
                            error.javaClass.simpleName,
                    )
                }.getOrDefault(emptyMap())
            }
            val lateNightEndMs = minOf(
                dayEndMs,
                DayMath.overnightEndFor(dayStartMs),
            )
            val lateNightApps = if (dayConfig.packages.isEmpty()) {
                emptyMap()
            } else {
                runCatching {
                    BlockUsage.secondsByPackage(
                        context,
                        dayStartMs,
                        lateNightEndMs,
                        dayConfig.packages,
                    )
                }.onFailure { error ->
                    LockoutLog.warn(
                        context,
                        "late-night query failed for $date: " +
                            error.javaClass.simpleName,
                    )
                }.getOrDefault(emptyMap())
            }
            val focusSeconds = current.focusSecondsInRange(
                dayStartMs,
                dayEndMs,
            )
            val total = apps.values.sum()
            val lateNightSeconds = lateNightApps.values.sum()
            if (total > 0 || focusSeconds > 0 || lateNightSeconds > 0) {
                ArchiveStore.append(
                    context,
                    UsageArchive(
                        date = date,
                        totalSeconds = total,
                        limitSeconds = dayConfig.limitSeconds,
                        limitHitAtMs = hitAtMsFor(
                            current,
                            dayStartMs,
                            dayEndMs,
                        ),
                        apps = apps,
                        focusSeconds = focusSeconds,
                        lateNightSeconds = lateNightSeconds,
                        lateNightApps = lateNightApps,
                    ),
                )
                archived = true
                val noun = if (apps.size == 1) "app" else "apps"
                LockoutLog.info(
                    context,
                    "archived $date across ${apps.size} $noun " +
                        "(focus ${focusSeconds}s, late ${lateNightSeconds}s)",
                )
            }

            // Mark even a day with no config or no usage, so the query is not
            // repeated on every two-second poll.
            ArchiveStore.markArchived(context, date)
        }

        // A focus timer used today keeps the watcher alive until midnight so the
        // finished day can be archived even if Flutter is never opened. Once the
        // day rolls over, bank any part of a cross-midnight session that belongs
        // to the new day and drop yesterday's stale timer state.
        val focusRoll = rollFocusDay(current, nowMs)
        if (focusRoll.changed) {
            current = focusRoll.config
            BlockingStore.save(context, current)
            LockoutLog.info(context, "focus tracking rolled into a new day")
        }

        var materialised = false
        val pendingUsable = current.pendingEffectiveAtMs > 0L &&
            current.pendingLimitSeconds > 0 &&
            current.pendingPackages.isNotEmpty()
        if (pendingUsable && nowMs >= current.pendingEffectiveAtMs) {
            current = current.copy(
                monitoredPackages = current.pendingPackages,
                dailyLimitSeconds = current.pendingLimitSeconds,
                pendingPackages = emptySet(),
                pendingLimitSeconds = 0,
                pendingEffectiveAtMs = 0L,
            )
            BlockingStore.save(context, current)
            // Keep Flutter's recurring-limit cache in step with the native
            // materialisation. Without this, a notification extension applied
            // after midnight could be overwritten by a stale pending value on
            // the next app launch.
            FlutterSettings.writeLimits(
                context,
                current.dailyLimitSeconds,
                null,
                null,
            )
            materialised = true
            LockoutLog.info(context, "scheduled app/limit change applied")
        }

        var cleared = false
        if (current.isLocked && nowMs >= current.nextResetAtMs) {
            current = LockState.clear(context, current, nowMs)
            cleared = true
        }

        // The daily limit is persistent, so an unlocked config can outlive the
        // day its reset timestamp was written for. Roll it forward as well;
        // otherwise a later lock/config sync would carry a stale reset date.
        var resetAdvanced = false
        if (!current.isLocked && nowMs >= current.nextResetAtMs) {
            val resetAtMs = DayMath.nextLocalMidnight(nowMs)
            current = current.copy(nextResetAtMs = resetAtMs)
            BlockingStore.saveLock(context, current)
            FlutterSettings.writeLock(context, false, 0L, resetAtMs)
            resetAdvanced = true
            LockoutLog.info(context, "daily reset date advanced")
        }

        return Result(
            current,
            archived,
            cleared,
            materialised,
            resetAdvanced,
            focusRoll.changed,
        )
    }

    /**
     * Moves focus tracking into [nowMs]'s local day.
     *
     * A timer that crosses midnight keeps running, but its base resets to zero
     * because the finished day has already been archived. A timer that ended
     * after midnight banks only the part inside the new day, so the next
     * midnight archive still sees it. Stale state from an earlier day is
     * cleared so the watcher can stop.
     */
    internal fun rollFocusDay(
        config: BlockingConfig,
        nowMs: Long,
    ): FocusRollResult {
        val todayStart = DayMath.startOfLocalDay(nowMs)
        if (config.focusDayStartMs == todayStart) {
            return FocusRollResult(config, false)
        }
        if (config.focusDayStartMs == 0L &&
            config.focusSessionStartedAtMs == 0L
        ) {
            return FocusRollResult(config, false)
        }

        val sessionStart = config.focusSessionStartedAtMs
        val sessionEnd = config.focusSessionEndsAtMs
        val running = sessionStart > 0L && sessionEnd > nowMs
        val rolled = if (running) {
            config.copy(
                focusDayStartMs = todayStart,
                focusBaseSeconds = 0,
            )
        } else {
            val from = maxOf(sessionStart, todayStart)
            val to = minOf(sessionEnd, nowMs)
            val bankedToday = if (sessionEnd > sessionStart && to > from) {
                ((to - from) / 1000L).toInt()
            } else {
                0
            }
            config.copy(
                focusDayStartMs = if (bankedToday > 0) todayStart else 0L,
                focusBaseSeconds = bankedToday,
                focusSessionStartedAtMs = 0L,
                focusSessionEndsAtMs = 0L,
            )
        }
        return FocusRollResult(rolled, rolled != config)
    }

    /**
     * Timestamp to show for the day's limit hit.
     *
     * - A lock stamped during the day stores its exact time.
     * - A lock that was already in force at 00:00 (a multi-day lock or a missed
     *   reset) is attributed to the start of that day; the real hit happened
     *   earlier and the schema has only one instant.
     */
    private fun hitAtMsFor(
        config: BlockingConfig,
        dayStartMs: Long,
        dayEndMs: Long,
    ): Long {
        if (!config.isLocked || config.lockedAtMs <= 0L) return 0L
        if (config.lockedAtMs in dayStartMs until dayEndMs) {
            return config.lockedAtMs
        }
        if (config.lockedAtMs < dayStartMs && config.nextResetAtMs > dayStartMs) {
            return dayStartMs
        }
        return 0L
    }
}

/** Result of rolling focus tracking into a new local day. */
internal data class FocusRollResult(
    val config: BlockingConfig,
    val changed: Boolean,
)
