package com.lockout.lockout.platform

import java.util.Calendar
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Catch-up archive planning: one day normally, a bounded gap after a long
 * absence, and no repeated work once the last date is current.
 */
class ArchivePlannerTest {

    private fun local(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
    ): Long = Calendar.getInstance().apply {
        clear()
        set(year, month, day, hour, 0, 0)
    }.timeInMillis

    private fun date(year: Int, month: Int, day: Int): String =
        DayMath.localDate(local(year, month, day))

    @Test
    fun `first run archives yesterday only`() {
        val now = local(2026, Calendar.NOVEMBER, 1)

        assertEquals(
            listOf(date(2026, Calendar.OCTOBER, 31)),
            ArchivePlanner.datesToArchive(null, now),
        )
    }

    @Test
    fun `already archived yesterday does nothing`() {
        val now = local(2026, Calendar.NOVEMBER, 1)

        assertEquals(
            emptyList<String>(),
            ArchivePlanner.datesToArchive("2026-10-31", now),
        )
    }

    @Test
    fun `a short gap archives every missing day in order`() {
        val now = local(2026, Calendar.NOVEMBER, 1)

        assertEquals(
            listOf("2026-10-29", "2026-10-30", "2026-10-31"),
            ArchivePlanner.datesToArchive("2026-10-28", now),
        )
    }

    @Test
    fun `a long gap is capped to the most recent days`() {
        val now = local(2026, Calendar.NOVEMBER, 1)

        val dates = ArchivePlanner.datesToArchive("2026-09-01", now)

        assertEquals(ArchivePlanner.MAX_CATCH_UP_DAYS, dates.size)
        assertEquals("2026-10-18", dates.first())
        assertEquals("2026-10-31", dates.last())
    }

    @Test
    fun `invalid or future last dates fall back to yesterday`() {
        val now = local(2026, Calendar.NOVEMBER, 1)

        assertEquals(
            listOf("2026-10-31"),
            ArchivePlanner.datesToArchive("not-a-date", now),
        )
        assertEquals(
            listOf("2026-10-31"),
            ArchivePlanner.datesToArchive("2026-11-02", now),
        )
    }

    @Test
    fun `the gap crosses a month and year boundary`() {
        val now = local(2027, Calendar.JANUARY, 2)

        assertEquals(
            listOf("2026-12-31", "2027-01-01"),
            ArchivePlanner.datesToArchive("2026-12-30", now),
        )
    }

    @Test
    fun `maxDays can be tightened for tests or future policy`() {
        val now = local(2026, Calendar.NOVEMBER, 1)

        val dates = ArchivePlanner.datesToArchive(
            lastArchivedDate = "2026-10-25",
            nowMs = now,
            maxDays = 2,
        )

        assertEquals(listOf("2026-10-30", "2026-10-31"), dates)
    }

    @Test
    fun `dates are always local date keys`() {
        val now = local(2026, Calendar.NOVEMBER, 1)

        val dates = ArchivePlanner.datesToArchive(null, now)

        assertTrue(dates.all { it.matches(Regex("""\d{4}-\d{2}-\d{2}""")) })
    }
}
