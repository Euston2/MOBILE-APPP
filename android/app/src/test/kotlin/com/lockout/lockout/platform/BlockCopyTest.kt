package com.lockout.lockout.platform

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The native block screen must show the same numbers as the Flutter Home
 * screen, so the duration formatting is pinned here.
 */
class BlockCopyTest {

    @Test
    fun `formats durations like the Dart formatter`() {
        assertEquals("0m", BlockCopy.formatDuration(0))
        assertEquals("<1m", BlockCopy.formatDuration(59))
        assertEquals("1m", BlockCopy.formatDuration(60))
        assertEquals("10m", BlockCopy.formatDuration(600))
        assertEquals("1h", BlockCopy.formatDuration(3600))
        assertEquals("1h 05m", BlockCopy.formatDuration(3900))
        assertEquals("1h 30m", BlockCopy.formatDuration(5400))
        assertEquals("0m", BlockCopy.formatDuration(-10))
    }

    @Test
    fun `titles distinguish the daily limit from each lock`() {
        assertEquals("Time's up", BlockCopy.title(BlockReason.LIMIT_REACHED))
        assertEquals("Locked until midnight", BlockCopy.title(BlockReason.LOCKED))
        assertEquals("Overnight lock", BlockCopy.title(BlockReason.OVERNIGHT))
        assertEquals("Study time", BlockCopy.title(BlockReason.STUDY))
    }

    @Test
    fun `detail includes used and limit time`() {
        val detail = BlockCopy.detail(BlockReason.LIMIT_REACHED, 3900, 3600)

        assertTrue(detail.contains("1h 05m"))
        assertTrue(detail.contains("1h daily limit"))
    }

    @Test
    fun `focus details explain the fixed window and study end`() {
        val overnight = BlockCopy.detail(BlockReason.OVERNIGHT, 0, 0)
        val study = BlockCopy.detail(
            BlockReason.STUDY,
            0,
            0,
            studyEndsAtMs = 2_000_000_000_000L,
        )

        assertTrue(overnight.contains("12:00 AM"))
        assertTrue(overnight.contains("8:00 AM"))
        assertTrue(study.contains("study lock is on until"))
        assertTrue(study.contains("Selected apps stay blocked"))
    }
}
