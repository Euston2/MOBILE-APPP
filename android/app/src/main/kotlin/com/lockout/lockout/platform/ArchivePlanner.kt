package com.lockout.lockout.platform

/**
 * Works out which finished local days still need an archive record.
 *
 * The reset used to archive only the previous day, so a device that stayed
 * force-stopped or powered off for a week silently lost the older days. This
 * planner fills the gap when Lockout next runs. It is capped so a long absence
 * or a corrupt preference cannot trigger an unbounded UsageStats query.
 *
 * Pure JVM code so the date arithmetic is testable without Android
 * (`ArchivePlannerTest`).
 */
object ArchivePlanner {

    /** Most recent missing days to recover in one pass. */
    const val MAX_CATCH_UP_DAYS = 14

    /**
     * Ascending `yyyy-MM-dd` keys to archive.
     *
     * - No/invalid/future last date: only yesterday, the original behaviour.
     * - Already up to date: empty.
     * - A real gap: every missing day, capped to the most recent
     *   [maxDays] days so old history is not scanned on every start.
     */
    fun datesToArchive(
        lastArchivedDate: String?,
        nowMs: Long,
        maxDays: Int = MAX_CATCH_UP_DAYS,
    ): List<String> {
        require(maxDays > 0) { "maxDays must be positive" }

        val todayStart = DayMath.startOfLocalDay(nowMs)
        val yesterdayStart = DayMath.startOfPreviousLocalDay(nowMs)
        val parsedLast = lastArchivedDate?.let(DayMath::parseLocalDate)

        // A current (yesterday) record means there is nothing to do. A future
        // record can happen after a clock change and is treated like a corrupt
        // one so yesterday is re-checked and the marker moves back.
        if (parsedLast != null && parsedLast >= yesterdayStart && parsedLast < todayStart) {
            return emptyList()
        }
        val lastStart = parsedLast?.takeIf { it < yesterdayStart }
        val from = if (lastStart == null) {
            yesterdayStart
        } else {
            DayMath.nextLocalMidnight(lastStart)
        }

        val dates = mutableListOf<String>()
        var cursor = from
        while (cursor < todayStart) {
            dates += DayMath.localDate(cursor)
            cursor = DayMath.nextLocalMidnight(cursor)
        }

        return if (dates.size > maxDays) dates.takeLast(maxDays) else dates
    }
}
