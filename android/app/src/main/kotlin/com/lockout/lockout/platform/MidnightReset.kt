package com.lockout.lockout.platform

import android.content.Context

/**
 * The one implementation of the midnight transition.
 *
 * Called from the alarm, from `BOOT_COMPLETED`/time-change receivers, from the
 * service start and from every poll. It is deliberately idempotent:
 * - yesterday is archived at most once per local date (`last_archived_date`);
 * - an expired lock is cleared only when `now >= next_reset_at`;
 * - a pending configuration is folded into the active one once due.
 *
 * Order matters. Archiving happens before the pending configuration is
 * materialised, and before the lock is cleared, because the archived day must
 * use the app set/limit that governed it and the lock timestamp is part of the
 * record. The pending set is used for yesterday only when it was already in
 * force at yesterday's midnight (for example when the app was not opened for a
 * few days).
 */
object MidnightReset {

    data class Result(
        val config: BlockingConfig,
        val archived: Boolean,
        val lockCleared: Boolean,
        val materialised: Boolean,
    ) {
        val changed: Boolean
            get() = archived || lockCleared || materialised
    }

    fun recover(
        context: Context,
        config: BlockingConfig = BlockingStore.load(context),
        nowMs: Long = System.currentTimeMillis(),
    ): Result {
        var current = config
        var archived = false

        val yesterdayStartMs = DayMath.startOfPreviousLocalDay(nowMs)
        val todayStartMs = DayMath.startOfLocalDay(nowMs)
        val yesterdayDate = DayMath.localDate(yesterdayStartMs)

        val pendingUsable = current.pendingEffectiveAtMs > 0L &&
            current.pendingLimitSeconds > 0 &&
            current.pendingPackages.isNotEmpty()

        // Which configuration governed yesterday? A pending config saved before
        // yesterday's midnight was already active for the whole day.
        val archivePending = pendingUsable &&
            current.pendingEffectiveAtMs <= yesterdayStartMs
        val archivePackages = if (archivePending) {
            current.pendingPackages
        } else {
            current.monitoredPackages
        }
        val archiveLimit = if (archivePending) {
            current.pendingLimitSeconds
        } else {
            current.dailyLimitSeconds
        }

        if (archivePackages.isNotEmpty() &&
            archiveLimit > 0 &&
            ArchiveStore.lastArchivedDate(context) != yesterdayDate
        ) {
            val apps = BlockUsage.secondsByPackage(
                context,
                yesterdayStartMs,
                todayStartMs,
                archivePackages,
            )
            val total = apps.values.sum()
            if (total > 0) {
                val hitAtMs = if (
                    current.isLocked &&
                    current.lockedAtMs >= yesterdayStartMs &&
                    current.lockedAtMs < todayStartMs
                ) {
                    current.lockedAtMs
                } else {
                    0L
                }
                ArchiveStore.append(
                    context,
                    UsageArchive(
                        date = yesterdayDate,
                        totalSeconds = total,
                        limitSeconds = archiveLimit,
                        limitHitAtMs = hitAtMs,
                        apps = apps,
                    ),
                )
                archived = true
            }
            // Mark even when the day had no usage, so the query is not repeated
            // on every poll.
            ArchiveStore.markArchived(context, yesterdayDate)
        }

        var materialised = false
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
        }

        var cleared = false
        if (current.isLocked && nowMs >= current.nextResetAtMs) {
            current = LockState.clear(context, current, nowMs)
            cleared = true
        }

        return Result(current, archived, cleared, materialised)
    }
}
