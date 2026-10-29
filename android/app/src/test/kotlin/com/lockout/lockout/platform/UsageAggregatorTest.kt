package com.lockout.lockout.platform

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit tests for the riskiest native logic: turning raw foreground events into
 * "seconds used since 00:00", including clipping at both window edges.
 *
 * Window start is 1_000_000 ms and end is 1_000_000 + one hour for readability.
 */
class UsageAggregatorTest {

    private val windowStart = 1_000_000L
    private val windowEnd = windowStart + 3_600_000L // 1 hour

    @Test
    fun `simple resume pause pair counts the interval`() {
        val events = listOf(
            UsageEvent(windowStart + 10_000, UsageAggregator.RESUMED, "com.instagram.android"),
            UsageEvent(windowStart + 70_000, UsageAggregator.PAUSED, "com.instagram.android"),
        )

        val result = UsageAggregator.aggregate(events, windowStart, windowEnd)

        assertEquals(60_000L, result["com.instagram.android"])
    }

    @Test
    fun `segment started before midnight is clipped to the window`() {
        val events = listOf(
            UsageEvent(windowStart - 600_000, UsageAggregator.RESUMED, "com.zhiliaoapp.musically"),
            UsageEvent(windowStart + 30_000, UsageAggregator.PAUSED, "com.zhiliaoapp.musically"),
        )

        val result = UsageAggregator.aggregate(events, windowStart, windowEnd)

        assertEquals(30_000L, result["com.zhiliaoapp.musically"])
    }

    @Test
    fun `app still open at window end is counted up to now`() {
        val events = listOf(
            UsageEvent(windowStart + 3_000_000, UsageAggregator.RESUMED, "com.twitter.android"),
        )

        val result = UsageAggregator.aggregate(events, windowStart, windowEnd)

        assertEquals(600_000L, result["com.twitter.android"])
    }

    @Test
    fun `switching apps without a pause closes the previous segment`() {
        val events = listOf(
            UsageEvent(windowStart + 10_000, UsageAggregator.RESUMED, "com.instagram.android"),
            UsageEvent(windowStart + 40_000, UsageAggregator.RESUMED, "com.facebook.katana"),
            UsageEvent(windowStart + 100_000, UsageAggregator.PAUSED, "com.facebook.katana"),
        )

        val result = UsageAggregator.aggregate(events, windowStart, windowEnd)

        assertEquals(30_000L, result["com.instagram.android"])
        assertEquals(60_000L, result["com.facebook.katana"])
    }

    @Test
    fun `screen off closes the open segment`() {
        val events = listOf(
            UsageEvent(windowStart + 10_000, UsageAggregator.RESUMED, "com.whatsapp"),
            UsageEvent(windowStart + 50_000, UsageAggregator.INTERRUPTED, ""),
            UsageEvent(windowStart + 200_000, UsageAggregator.PAUSED, "com.whatsapp"),
        )

        val result = UsageAggregator.aggregate(events, windowStart, windowEnd)

        assertEquals(40_000L, result["com.whatsapp"])
    }

    @Test
    fun `events after the window end are ignored`() {
        val events = listOf(
            UsageEvent(windowEnd + 5_000, UsageAggregator.RESUMED, "com.snapchat.android"),
            UsageEvent(windowEnd + 15_000, UsageAggregator.PAUSED, "com.snapchat.android"),
        )

        val result = UsageAggregator.aggregate(events, windowStart, windowEnd)

        assertTrue(result.isEmpty())
    }

    @Test
    fun `resume of the same package does not double count`() {
        val events = listOf(
            UsageEvent(windowStart, UsageAggregator.RESUMED, "com.google.android.youtube"),
            UsageEvent(windowStart + 20_000, UsageAggregator.RESUMED, "com.google.android.youtube"),
            UsageEvent(windowStart + 50_000, UsageAggregator.PAUSED, "com.google.android.youtube"),
        )

        val result = UsageAggregator.aggregate(events, windowStart, windowEnd)

        assertEquals(50_000L, result["com.google.android.youtube"])
    }

    @Test
    fun `paused event for a different package is ignored`() {
        val events = listOf(
            UsageEvent(windowStart + 10_000, UsageAggregator.RESUMED, "com.android.chrome"),
            UsageEvent(windowStart + 20_000, UsageAggregator.PAUSED, "com.other.app"),
            UsageEvent(windowStart + 60_000, UsageAggregator.PAUSED, "com.android.chrome"),
        )

        val result = UsageAggregator.aggregate(events, windowStart, windowEnd)

        assertEquals(50_000L, result["com.android.chrome"])
    }

    @Test
    fun `empty window returns nothing`() {
        assertTrue(UsageAggregator.aggregate(emptyList(), windowStart, windowStart).isEmpty())
    }
}
