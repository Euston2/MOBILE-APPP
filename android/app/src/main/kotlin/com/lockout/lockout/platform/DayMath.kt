package com.lockout.lockout.platform

import java.text.ParsePosition
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

    /** Fixed overnight focus window, mirroring `lib/core/utils/focus_window.dart`. */
    const val OVERNIGHT_START_HOUR = 0
    const val OVERNIGHT_END_HOUR = 8

    /** True between local 00:00 (inclusive) and 08:00 (exclusive). */
    fun isInOvernightWindow(nowMs: Long): Boolean {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = nowMs
        val hour = calendar.get(Calendar.HOUR_OF_DAY)
        return hour >= OVERNIGHT_START_HOUR && hour < OVERNIGHT_END_HOUR
    }

    /** Local 08:00 on the day that contains [nowMs]. */
    fun overnightEndFor(nowMs: Long): Long {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = nowMs
        calendar.set(Calendar.HOUR_OF_DAY, OVERNIGHT_END_HOUR)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }

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

    /**
     * Parses a strict `yyyy-MM-dd` key back to local midnight.
     *
     * Returns null for malformed or impossible dates, and for trailing text, so
     * a corrupt preference cannot make the catch-up archive loop forever.
     */
    fun parseLocalDate(date: String): Long? {
        if (date.length != 10) return null
        val format = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
            isLenient = false
        }
        val position = ParsePosition(0)
        val parsed = format.parse(date, position) ?: return null
        if (position.index != date.length) return null
        return startOfLocalDay(parsed.time)
    }
}
