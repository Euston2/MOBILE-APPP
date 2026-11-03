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
    ) {
        val changed: Boolean
            get() = archived || lockCleared || materialised || resetAdvanced
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
            if (dayConfig.isActive) {
                val apps = runCatching {
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
                val total = apps.values.sum()
                if (total > 0) {
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
                        ),
                    )
                    archived = true
                    val noun = if (apps.size == 1) "app" else "apps"
                    LockoutLog.info(
                        context,
                        "archived $date across ${apps.size} $noun",
                    )
                }
            }

            // Mark even a day with no config or no usage, so the query is not
            // repeated on every two-second poll.
            ArchiveStore.markArchived(context, date)
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
        )
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
