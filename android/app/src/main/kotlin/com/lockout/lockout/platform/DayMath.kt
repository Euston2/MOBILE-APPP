package com.lockout.lockout.platform

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Local-day arithmetic used by the lock, the reset and the archive.
 *
 * Pure JVM code (no Android imports) so DST and timezone rules can be tested
 * with `DayMathTest`. Mirrors `lib/core/utils/day_window.dart`.
 */
object DayMath {

    /** Local 00:00 of the day that contains [nowMs]. */
    fun startOfLocalDay(nowMs: Long): Long {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = nowMs
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }

    /** Local 00:00 of the day before [nowMs] (DST-safe via Calendar). */
    fun startOfPreviousLocalDay(nowMs: Long): Long {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = startOfLocalDay(nowMs)
        calendar.add(Calendar.DAY_OF_YEAR, -1)
        return calendar.timeInMillis
    }

    /**
     * Next local 00:00 strictly after [nowMs].
     *
     * At exactly midnight this is the following midnight, so clearing a lock at
     * 00:00 does not immediately recreate it for the same instant.
     */
    fun nextLocalMidnight(nowMs: Long): Long {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = nowMs
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        calendar.add(Calendar.DAY_OF_YEAR, 1)
        return calendar.timeInMillis
    }

    /** Local date key (`yyyy-MM-dd`) used by the archive and drift. */
    fun localDate(nowMs: Long): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(nowMs))
}
