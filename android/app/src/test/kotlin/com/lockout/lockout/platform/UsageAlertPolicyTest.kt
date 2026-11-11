package com.lockout.lockout.platform

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class UsageAlertPolicyTest {

    @Test
    fun `remaining time clamps at zero and ignores a missing limit`() {
        assertEquals(3600, UsageAlertPolicy.remainingSeconds(3600, 0))
        assertEquals(300, UsageAlertPolicy.remainingSeconds(3600, 3300))
        assertEquals(0, UsageAlertPolicy.remainingSeconds(3600, 3900))
        assertEquals(0, UsageAlertPolicy.remainingSeconds(0, 100))
    }

    @Test
    fun `tier maps to the most urgent warning at or above the allowance`() {
        assertEquals(3600, UsageAlertPolicy.tierFor(3600))
        assertEquals(1800, UsageAlertPolicy.tierFor(1700))
        assertEquals(900, UsageAlertPolicy.tierFor(800))
        assertEquals(300, UsageAlertPolicy.tierFor(299))
        assertNull(UsageAlertPolicy.tierFor(3700))
    }

    @Test
    fun `crossing reports only a downward threshold crossing`() {
        assertEquals(
            1800,
            UsageAlertPolicy.crossedThreshold(
                previousRemainingSeconds = 2000,
                currentRemainingSeconds = 1700,
            ),
        )
        assertEquals(
            300,
            UsageAlertPolicy.crossedThreshold(
                previousRemainingSeconds = 2000,
                currentRemainingSeconds = 200,
            ),
        )
        assertNull(
            UsageAlertPolicy.crossedThreshold(
                previousRemainingSeconds = 1700,
                currentRemainingSeconds = 1650,
            ),
        )
        assertNull(
            UsageAlertPolicy.crossedThreshold(
                previousRemainingSeconds = 200,
                currentRemainingSeconds = 900,
            ),
        )
    }

    @Test
    fun `a fresh start warns at five minutes or less and on an exact tier`() {
        assertTrue(UsageAlertPolicy.shouldNotifyOnFreshStart(3600))
        assertTrue(UsageAlertPolicy.shouldNotifyOnFreshStart(1800))
        assertTrue(UsageAlertPolicy.shouldNotifyOnFreshStart(900))
        assertTrue(UsageAlertPolicy.shouldNotifyOnFreshStart(300))
        assertTrue(UsageAlertPolicy.shouldNotifyOnFreshStart(1))
        assertFalse(UsageAlertPolicy.shouldNotifyOnFreshStart(901))
        assertFalse(UsageAlertPolicy.shouldNotifyOnFreshStart(0))
    }

    @Test
    fun `marking passed thresholds suppresses older warnings`() {
        val mask = UsageAlertPolicy.markPassed(0, 1700)

        assertTrue(
            UsageAlertPolicy.hasNotified(mask, UsageAlertPolicy.ONE_HOUR_SECONDS),
        )
        assertTrue(
            UsageAlertPolicy.hasNotified(
                mask,
                UsageAlertPolicy.THIRTY_MINUTES_SECONDS,
            ),
        )
        assertFalse(
            UsageAlertPolicy.hasNotified(
                mask,
                UsageAlertPolicy.FIFTEEN_MINUTES_SECONDS,
            ),
        )
        assertFalse(
            UsageAlertPolicy.hasNotified(
                mask,
                UsageAlertPolicy.FIVE_MINUTES_SECONDS,
            ),
        )
    }

    @Test
    fun `the five minute warning explains the native extension`() {
        val body = UsageAlertPolicy.bodyFor(
            thresholdSeconds = UsageAlertPolicy.FIVE_MINUTES_SECONDS,
            remainingSeconds = 240,
            appCount = 3,
        )

        assertTrue(body.contains("4m left"))
        assertTrue(body.contains("3 apps"))
        assertTrue(body.contains("Add 10 minutes"))
        assertEquals(
            "5 minutes left",
            UsageAlertPolicy.titleFor(UsageAlertPolicy.FIVE_MINUTES_SECONDS),
        )
    }
}
