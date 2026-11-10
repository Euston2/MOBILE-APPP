package com.lockout.lockout.platform

import java.util.Calendar
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/** Tests for rolling a focus timer into the next local day. */
class MidnightResetTest {

    private fun local(
        day: Int,
        hour: Int,
        minute: Int = 0,
    ): Long = Calendar.getInstance().apply {
        clear()
        set(2026, Calendar.NOVEMBER, day, hour, minute, 0)
    }.timeInMillis

    private fun config(
        dayStart: Long,
        baseSeconds: Int = 0,
        sessionStart: Long = 0L,
        sessionEnd: Long = 0L,
    ) = BlockingConfig(
        monitoredPackages = setOf("com.instagram.android"),
        dailyLimitSeconds = 0,
        focusDayStartMs = dayStart,
        focusBaseSeconds = baseSeconds,
        focusSessionStartedAtMs = sessionStart,
        focusSessionEndsAtMs = sessionEnd,
    )

    @Test
    fun `a session crossing midnight keeps running with a fresh base`() {
        val start = local(9, 23, 50)
        val end = local(10, 0, 20)
        val now = local(10, 0, 5)
        val original = config(
            dayStart = DayMath.startOfLocalDay(start),
            baseSeconds = 1200,
            sessionStart = start,
            sessionEnd = end,
        )

        val result = MidnightReset.rollFocusDay(original, now)

        assertTrue(result.changed)
        assertEquals(DayMath.startOfLocalDay(now), result.config.focusDayStartMs)
        assertEquals(0, result.config.focusBaseSeconds)
        assertEquals(start, result.config.focusSessionStartedAtMs)
        assertEquals(end, result.config.focusSessionEndsAtMs)
        assertEquals(300, result.config.focusSecondsAt(now))
    }

    @Test
    fun `a session ending after midnight banks only the new day part`() {
        val start = local(9, 23, 50)
        val end = local(10, 0, 20)
        val now = local(10, 0, 30)
        val original = config(
            dayStart = DayMath.startOfLocalDay(start),
            baseSeconds = 1200,
            sessionStart = start,
            sessionEnd = end,
        )

        val result = MidnightReset.rollFocusDay(original, now)

        assertTrue(result.changed)
        assertEquals(DayMath.startOfLocalDay(now), result.config.focusDayStartMs)
        assertEquals(20 * 60, result.config.focusBaseSeconds)
        assertEquals(0L, result.config.focusSessionStartedAtMs)
        assertEquals(0L, result.config.focusSessionEndsAtMs)
    }

    @Test
    fun `an old timer that ended before midnight is cleared`() {
        val start = local(9, 10)
        val end = local(9, 11)
        val now = local(10, 12)
        val original = config(
            dayStart = DayMath.startOfLocalDay(start),
            baseSeconds = 3600,
            sessionStart = start,
            sessionEnd = end,
        )

        val result = MidnightReset.rollFocusDay(original, now)

        assertTrue(result.changed)
        assertEquals(0L, result.config.focusDayStartMs)
        assertEquals(0, result.config.focusBaseSeconds)
        assertEquals(0L, result.config.focusSessionStartedAtMs)
        assertEquals(0L, result.config.focusSessionEndsAtMs)
    }

    @Test
    fun `today's tracking state is left untouched`() {
        val now = local(10, 12)
        val original = config(
            dayStart = DayMath.startOfLocalDay(now),
            baseSeconds = 600,
        )

        val result = MidnightReset.rollFocusDay(original, now)

        assertFalse(result.changed)
        assertSame(original, result.config)
    }

    @Test
    fun `no focus state is left untouched`() {
        val now = local(10, 12)
        val original = config(dayStart = 0L)

        val result = MidnightReset.rollFocusDay(original, now)

        assertFalse(result.changed)
        assertSame(original, result.config)
    }
}
