package com.lockout.lockout.platform

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Boundary tests for the blocking decision. These cases are what the service,
 * the block activity and the overlay all rely on, so they must not disagree.
 */
class BlockPolicyTest {

    private val now = 2_000_000L
    private val config = BlockingConfig(
        monitoredPackages = setOf("com.instagram.android", "com.zhiliaoapp.musically"),
        dailyLimitSeconds = 3600,
        isLocked = false,
        nextResetAtMs = now + 3_600_000L,
    )

    @Test
    fun `unmonitored app is never blocked`() {
        val reason = BlockPolicy.reasonForForeground(
            foregroundPackage = "com.android.chrome",
            config = config,
            usedSecondsToday = 10_000,
            nowMs = now,
        )

        assertNull(reason)
    }

    @Test
    fun `no foreground app is never blocked`() {
        val reason = BlockPolicy.reasonForForeground(
            foregroundPackage = null,
            config = config,
            usedSecondsToday = 10_000,
            nowMs = now,
        )

        assertNull(reason)
    }

    @Test
    fun `monitored app under the limit is allowed`() {
        val reason = BlockPolicy.reasonForForeground(
            foregroundPackage = "com.instagram.android",
            config = config,
            usedSecondsToday = 3599,
            nowMs = now,
        )

        assertNull(reason)
    }

    @Test
    fun `reaching the limit exactly blocks`() {
        val reason = BlockPolicy.reasonForForeground(
            foregroundPackage = "com.instagram.android",
            config = config,
            usedSecondsToday = 3600,
            nowMs = now,
        )

        assertEquals(BlockReason.LIMIT_REACHED, reason)
    }

    @Test
    fun `over the limit blocks`() {
        val reason = BlockPolicy.reasonForForeground(
            foregroundPackage = "com.zhiliaoapp.musically",
            config = config,
            usedSecondsToday = 4200,
            nowMs = now,
        )

        assertEquals(BlockReason.LIMIT_REACHED, reason)
    }

    @Test
    fun `active lock blocks even when the counter is under the limit`() {
        val locked = config.copy(isLocked = true)

        val reason = BlockPolicy.reasonForForeground(
            foregroundPackage = "com.instagram.android",
            config = locked,
            usedSecondsToday = 60,
            nowMs = now,
        )

        assertEquals(BlockReason.LOCKED, reason)
    }

    @Test
    fun `expired lock no longer blocks`() {
        val expired = config.copy(isLocked = true, nextResetAtMs = now - 1)

        val reason = BlockPolicy.reasonForForeground(
            foregroundPackage = "com.instagram.android",
            config = expired,
            usedSecondsToday = 60,
            nowMs = now,
        )

        assertNull(reason)
    }

    @Test
    fun `expired lock still blocks while the counter is over the limit`() {
        val expired = config.copy(isLocked = true, nextResetAtMs = now - 1)

        val reason = BlockPolicy.reasonForForeground(
            foregroundPackage = "com.instagram.android",
            config = expired,
            usedSecondsToday = 3600,
            nowMs = now,
        )

        assertEquals(BlockReason.LIMIT_REACHED, reason)
    }

    @Test
    fun `no configured limit never blocks`() {
        val unlimited = config.copy(dailyLimitSeconds = 0)

        val reason = BlockPolicy.reasonForForeground(
            foregroundPackage = "com.instagram.android",
            config = unlimited,
            usedSecondsToday = 100_000,
            nowMs = now,
        )

        assertNull(reason)
    }

    @Test
    fun `activity state check does not need a foreground package`() {
        assertEquals(
            BlockReason.LIMIT_REACHED,
            BlockPolicy.reasonFor(config, usedSecondsToday = 3600, nowMs = now),
        )
        assertNull(BlockPolicy.reasonFor(config, usedSecondsToday = 10, nowMs = now))
    }

    @Test
    fun `scheduled limit is ignored before its effective instant`() {
        val scheduled = config.copy(
            pendingPackages = setOf("com.android.chrome"),
            pendingLimitSeconds = 600,
            pendingEffectiveAtMs = now + 3_600_000L,
        )

        // Instagram is still monitored with the old 1 h limit.
        assertNull(
            BlockPolicy.reasonForForeground(
                foregroundPackage = "com.instagram.android",
                config = scheduled,
                usedSecondsToday = 600,
                nowMs = now,
            ),
        )
        // Chrome is not monitored yet.
        assertNull(
            BlockPolicy.reasonForForeground(
                foregroundPackage = "com.android.chrome",
                config = scheduled,
                usedSecondsToday = 600,
                nowMs = now,
            ),
        )
    }

    @Test
    fun `scheduled configuration takes over at midnight`() {
        val scheduled = config.copy(
            pendingPackages = setOf("com.android.chrome"),
            pendingLimitSeconds = 600,
            pendingEffectiveAtMs = now,
        )

        assertNull(
            BlockPolicy.reasonForForeground(
                foregroundPackage = "com.instagram.android",
                config = scheduled,
                usedSecondsToday = 10_000,
                nowMs = now,
            ),
        )
        assertEquals(
            BlockReason.LIMIT_REACHED,
            BlockPolicy.reasonForForeground(
                foregroundPackage = "com.android.chrome",
                config = scheduled,
                usedSecondsToday = 600,
                nowMs = now,
            ),
        )
    }

    @Test
    fun `shouldLock only when the effective limit is reached`() {
        assertFalse(BlockPolicy.shouldLock(config, usedSecondsToday = 3599, nowMs = now))
        assertTrue(BlockPolicy.shouldLock(config, usedSecondsToday = 3600, nowMs = now))

        val locked = config.copy(isLocked = true, nextResetAtMs = now + 1000L)
        assertFalse(BlockPolicy.shouldLock(locked, usedSecondsToday = 3600, nowMs = now))
    }

    @Test
    fun `a pending configuration keeps the watcher active`() {
        val pendingOnly = BlockingConfig(
            monitoredPackages = emptySet(),
            dailyLimitSeconds = 0,
            pendingPackages = setOf("com.instagram.android"),
            pendingLimitSeconds = 1800,
            pendingEffectiveAtMs = now + 1000L,
        )

        assertTrue(pendingOnly.isActive)
        assertFalse(
            BlockPolicy.shouldLock(
                pendingOnly,
                usedSecondsToday = 10_000,
                nowMs = now,
            ),
        )
    }
}
