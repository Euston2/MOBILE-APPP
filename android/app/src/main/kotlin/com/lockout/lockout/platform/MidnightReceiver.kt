package com.lockout.lockout.platform

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receives the exact midnight alarm.
 *
 * The receiver runs without Flutter. It archives yesterday, clears an expired
 * lock, and re-arms the next alarm. It does not try to start the foreground
 * service: Android 12+ restricts background service starts, and the sticky
 * service is normally already running; if it is not, the next poll/start
 * performs the same recovery.
 */
class MidnightReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        LockoutLog.info(context, "midnight alarm received")
        val result = MidnightReset.recover(context)
        val nowMs = System.currentTimeMillis()
        if (result.config.isActive) {
            MidnightAlarm.scheduleNext(context, nowMs)
        } else {
            MidnightAlarm.cancel(context)
        }
    }
}
