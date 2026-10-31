package com.lockout.lockout.platform

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Recovers after a reboot or a clock/time-zone change.
 *
 * AlarmManager alarms do not survive a reboot, so [MidnightAlarm] must be armed
 * again. The same handler is used for `TIME_SET` and `TIMEZONE_CHANGED`: a clock
 * jump can cross midnight, and the lock/reset decision must be re-evaluated.
 *
 * Starting the foreground service from `BOOT_COMPLETED` is one of the platform's
 * allowed exemptions; failures are ignored because the next app launch pushes
 * the config again.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val result = MidnightReset.recover(context)
        val nowMs = System.currentTimeMillis()

        if (!result.config.isActive) {
            MidnightAlarm.cancel(context)
            return
        }

        MidnightAlarm.scheduleNext(context, nowMs)
        try {
            BlockingService.start(context)
        } catch (_: Exception) {
            // Background-start restriction or missing permission; the service
            // will be started by the next config push.
        }
    }
}
