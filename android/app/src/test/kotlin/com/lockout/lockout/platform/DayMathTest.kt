package com.lockout.lockout.platform

import java.util.Calendar
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Boundary tests for the local-day arithmetic used by the lock and reset. */
class DayMathTest {

    private fun local(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
    ): Long = Calendar.getInstance().apply {
        clear()
        set(year, month, day, hour, minute, 0)
    }.timeInMillis

    private fun Calendar.part(part: Int) = get(part)

    @Test
    fun `start of day is local midnight`() {
        val afternoon = local(2026, Calendar.OCTOBER, 30, 15, 42)

        val start = DayMath.startOfLocalDay(afternoon)
        val calendar = Calendar.getInstance().apply { timeInMillis = start }

        assertEquals(0, calendar.part(Calendar.HOUR_OF_DAY))
        assertEquals(0, calendar.part(Calendar.MINUTE))
        assertEquals(30, calendar.part(Calendar.DAY_OF_MONTH))
    }

    @Test
    fun `next midnight is strictly in the future`() {
        val evening = local(2026, Calendar.OCTOBER, 30, 23, 59)

        val next = DayMath.nextLocalMidnight(evening)
        val calendar = Calendar.getInstance().apply { timeInMillis = next }

        assertTrue(next > evening)
        assertEquals(0, calendar.part(Calendar.HOUR_OF_DAY))
        assertEquals(31, calendar.part(Calendar.DAY_OF_MONTH))
    }

    @Test
    fun `at exactly midnight the next reset is the following day`() {
        val midnight = local(2026, Calendar.OCTOBER, 30)

        val next = DayMath.nextLocalMidnight(midnight)
        val calendar = Calendar.getInstance().apply { timeInMillis = next }

        assertEquals(31, calendar.part(Calendar.DAY_OF_MONTH))
        assertEquals(0, calendar.part(Calendar.HOUR_OF_DAY))
    }

    @Test
    fun `previous day starts 24 local hours earlier`() {
        val afternoon = local(2026, Calendar.OCTOBER, 30, 12)

        val previous = DayMath.startOfPreviousLocalDay(afternoon)
        val calendar = Calendar.getInstance().apply { timeInMillis = previous }

        assertEquals(29, calendar.part(Calendar.DAY_OF_MONTH))
        assertEquals(0, calendar.part(Calendar.HOUR_OF_DAY))
    }

    @Test
    fun `overnight window runs from midnight until eight`() {
        assertTrue(
            DayMath.isInOvernightWindow(local(2026, Calendar.NOVEMBER, 3)),
        )
        assertTrue(
            DayMath.isInOvernightWindow(
                local(2026, Calendar.NOVEMBER, 3, 7, 59),
            ),
        )
        assertFalse(
            DayMath.isInOvernightWindow(local(2026, Calendar.NOVEMBER, 3, 8)),
        )
        assertFalse(
            DayMath.isInOvernightWindow(
                local(2026, Calendar.NOVEMBER, 3, 23, 59),
            ),
        )
    }

    @Test
    fun `overnight end is eight on the same local day`() {
        val atThree = local(2026, Calendar.NOVEMBER, 3, 3, 17)

        val end = DayMath.overnightEndFor(atThree)
        val calendar = Calendar.getInstance().apply { timeInMillis = end }

        assertEquals(3, calendar.part(Calendar.DAY_OF_MONTH))
        assertEquals(8, calendar.part(Calendar.HOUR_OF_DAY))
        assertEquals(0, calendar.part(Calendar.MINUTE))
    }

    @Test
    fun `minute of local day counts from midnight`() {
        assertEquals(0, DayMath.minuteOfLocalDay(local(2026, Calendar.NOVEMBER, 3)))
        assertEquals(
            20 * 60,
            DayMath.minuteOfLocalDay(local(2026, Calendar.NOVEMBER, 3, 20)),
        )
        assertEquals(
            23 * 60 + 59,
            DayMath.minuteOfLocalDay(local(2026, Calendar.NOVEMBER, 3, 23, 59)),
        )
    }

    @Test
    fun `local date uses the yyyy-MM-dd key`() {
        val afternoon = local(2026, Calendar.OCTOBER, 30, 12)

        assertEquals("2026-10-30", DayMath.localDate(afternoon))
    }

    @Test
    fun `parseLocalDate returns local midnight`() {
        val parsed = DayMath.parseLocalDate("2026-10-31")
        val calendar = Calendar.getInstance().apply { timeInMillis = parsed!! }

        assertEquals(2026, calendar.part(Calendar.YEAR))
        assertEquals(Calendar.OCTOBER, calendar.part(Calendar.MONTH))
        assertEquals(31, calendar.part(Calendar.DAY_OF_MONTH))
        assertEquals(0, calendar.part(Calendar.HOUR_OF_DAY))
        assertEquals(0, calendar.part(Calendar.MINUTE))
    }

    @Test
    fun `parseLocalDate rejects malformed and impossible dates`() {
        assertEquals(null, DayMath.parseLocalDate("2026-2-03"))
        assertEquals(null, DayMath.parseLocalDate("2026-13-01"))
        assertEquals(null, DayMath.parseLocalDate("2026-02-30"))
        assertEquals(null, DayMath.parseLocalDate("2026-10-31x"))
        assertEquals(null, DayMath.parseLocalDate(""))
    }

    @Test
    fun `parseLocalDate round-trips leap day`() {
        val parsed = DayMath.parseLocalDate("2028-02-29")

        assertEquals("2028-02-29", DayMath.localDate(parsed!!))
    }
}
