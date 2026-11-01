package com.lockout.lockout.platform

import org.junit.Assert.assertEquals
import org.junit.Test

/** Sanitising rules for the bounded, on-device diagnostic log. */
class LockoutLogTest {

    @Test
    fun `newlines are flattened so one event stays one line`() {
        assertEquals(
            "service started watch failed",
            LockoutLog.sanitize("service started\n watch\r\n failed"),
        )
    }

    @Test
    fun `outer whitespace is trimmed`() {
        assertEquals("archived 2026-10-31", LockoutLog.sanitize("  archived 2026-10-31  "))
    }

    @Test
    fun `long messages are bounded`() {
        val safe = LockoutLog.sanitize("x".repeat(500))

        assertEquals(LockoutLog.MAX_MESSAGE_LENGTH, safe.length)
    }

    @Test
    fun `blank messages are discarded by the caller`() {
        assertEquals("", LockoutLog.sanitize(" \n\r "))
    }
}
