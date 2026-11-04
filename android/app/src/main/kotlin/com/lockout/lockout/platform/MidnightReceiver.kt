package com.lockout.lockout.platform

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receives the exact midnight alarm.
 *
 * The receiver runs without Flutter. It archives yesterday, clears an expired
 * lock, folds in a pending configuration, rolls the daily reset forward and
 * re-arms the next alarm.
 *
 * It also asks the foreground watcher to start. The service is normally already
 * running, but an OEM battery manager can kill it overnight; without this kick
 * the next day's persistent limit would not be enforced until the user opened
 * Lockout again. Exact alarms are one of the platform's allowed background
 * foreground-service starts, and a restriction failure is harmless because the
 * sticky service or the next app launch recovers it.
 */
class MidnightReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        LockoutLog.info(context, "midnight alarm received")
        val result = MidnightReset.recover(context)
        val nowMs = System.currentTimeMillis()
        if (!result.config.isActiveAt(nowMs)) {
            MidnightAlarm.cancel(context)
            return
        }

        MidnightAlarm.scheduleNext(context, nowMs)
        try {
            BlockingService.start(context)
        } catch (error: Exception) {
            // Background-start restriction; the next service/app start performs
            // the same recovery.
            LockoutLog.warn(
                context,
                "could not restart watcher at midnight: " +
                    error.javaClass.simpleName,
            )
        }
    }
}
