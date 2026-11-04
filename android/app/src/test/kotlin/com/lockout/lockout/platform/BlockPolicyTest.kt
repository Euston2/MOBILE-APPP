package com.lockout.lockout.platform

import java.util.Calendar
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

    private fun localTime(hour: Int, minute: Int = 0): Long =
        Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis

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
    fun `daily limit stays active on later days`() {
        val threeDaysLater = now + 3L * 24L * 60L * 60L * 1_000L

        val active = config.effectiveAt(threeDaysLater)

        assertTrue(config.isActive)
        assertEquals(config.dailyLimitSeconds, active.limitSeconds)
        assertEquals(config.monitoredPackages, active.packages)
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

    @Test
    fun `overnight lock blocks a selected app inside its window`() {
        val focus = config.copy(overnightLockEnabled = true)

        val atMidnight = BlockPolicy.reasonForForeground(
            foregroundPackage = "com.instagram.android",
            config = focus,
            usedSecondsToday = 0,
            nowMs = localTime(0),
        )
        val beforeEight = BlockPolicy.reasonForForeground(
            foregroundPackage = "com.zhiliaoapp.musically",
            config = focus,
            usedSecondsToday = 0,
            nowMs = localTime(7, 59),
        )

        assertEquals(BlockReason.OVERNIGHT, atMidnight)
        assertEquals(BlockReason.OVERNIGHT, beforeEight)
    }

    @Test
    fun `overnight lock releases at eight and ignores unmonitored apps`() {
        val focus = config.copy(overnightLockEnabled = true)

        assertNull(
            BlockPolicy.reasonForForeground(
                foregroundPackage = "com.instagram.android",
                config = focus,
                usedSecondsToday = 0,
                nowMs = localTime(8),
            ),
        )
        assertNull(
            BlockPolicy.reasonForForeground(
                foregroundPackage = "com.android.chrome",
                config = focus,
                usedSecondsToday = 0,
                nowMs = localTime(3),
            ),
        )
    }

    @Test
    fun `study lock blocks regardless of usage until its exact end`() {
        val study = config.copy(
            dailyLimitSeconds = 0,
            studyEndsAtMs = localTime(15) + 60_000L,
        )
        val during = BlockPolicy.reasonForForeground(
            foregroundPackage = "com.instagram.android",
            config = study,
            usedSecondsToday = 0,
            nowMs = localTime(15),
        )
        val atEnd = BlockPolicy.reasonForForeground(
            foregroundPackage = "com.instagram.android",
            config = study,
            usedSecondsToday = 0,
            nowMs = localTime(15) + 60_000L,
        )

        assertEquals(BlockReason.STUDY, during)
        assertNull(atEnd)
    }

    @Test
    fun `study lock takes priority over the overnight lock`() {
        val both = config.copy(
            studyEndsAtMs = localTime(4),
            overnightLockEnabled = true,
        )

        assertEquals(
            BlockReason.STUDY,
            BlockPolicy.reasonForForeground(
                foregroundPackage = "com.instagram.android",
                config = both,
                usedSecondsToday = 0,
                nowMs = localTime(3),
            ),
        )
    }

    @Test
    fun `focus locks do nothing without selected apps`() {
        val focus = BlockingConfig(
            monitoredPackages = emptySet(),
            dailyLimitSeconds = 0,
            overnightLockEnabled = true,
            studyEndsAtMs = now + 60_000L,
        )

        assertNull(
            BlockPolicy.reasonFor(
                focus,
                usedSecondsToday = 0,
                nowMs = localTime(3),
            ),
        )
    }

    @Test
    fun `focus configuration decides whether the watcher is still needed`() {
        val overnight = config.copy(
            dailyLimitSeconds = 0,
            overnightLockEnabled = true,
        )
        val study = config.copy(
            dailyLimitSeconds = 0,
            studyEndsAtMs = now + 60_000L,
        )

        assertTrue(overnight.isActiveAt(localTime(12)))
        assertTrue(study.isActiveAt(now))
        assertFalse(study.isActiveAt(now + 60_000L))
    }
}
