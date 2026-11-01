package com.lockout.lockout.platform

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Exact alarm at local midnight.
 *
 * The alarm is an optimisation, not the source of truth: every service poll and
 * every app start also compares the clock with `next_reset_at`, so a missed
 * alarm (force-stop, OEM task killer, device off) still recovers correctly.
 *
 * `SCHEDULE_EXACT_ALARM` is a special access on Android 12+. When it has not
 * been granted, the alarm is scheduled with the inexact-but-doze-safe
 * [AlarmManager.setAndAllowWhileIdle]; the next poll recovers the reset if the
 * system delays it.
 */
object MidnightAlarm {

    const val ACTION_RESET = "com.lockout.lockout.action.MIDNIGHT_RESET"

    private const val REQUEST_CODE = 4_231

    fun scheduleNext(context: Context, nowMs: Long) {
        scheduleAt(context, DayMath.nextLocalMidnight(nowMs))
    }

    /** Whether the OS will honour an exact alarm right now. */
    fun canScheduleExact(context: Context): Boolean {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            ?: return false
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            manager.canScheduleExactAlarms()
    }

    fun scheduleAt(context: Context, atMs: Long) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            ?: return
        val target = maxOf(atMs, System.currentTimeMillis() + 1_000L)
        val pending = pendingIntent(context)
        val exact = canScheduleExact(context)

        try {
            if (exact) {
                manager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    target,
                    pending,
                )
            } else {
                manager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    target,
                    pending,
                )
                LockoutLog.warn(
                    context,
                    "exact alarms unavailable; armed a doze-safe inexact reset",
                )
            }
            LockoutLog.info(
                context,
                "reset alarm armed for ${DayMath.localDate(target)}",
            )
        } catch (error: SecurityException) {
            // Exact-alarm access can be revoked between the check and the call.
            try {
                manager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    target,
                    pending,
                )
                LockoutLog.warn(
                    context,
                    "exact alarm was revoked; armed a doze-safe inexact reset",
                )
            } catch (fallbackError: Exception) {
                LockoutLog.error(
                    context,
                    "could not arm the reset alarm: " +
                        fallbackError.javaClass.simpleName,
                )
            }
        } catch (error: Exception) {
            LockoutLog.error(
                context,
                "could not arm the reset alarm: ${error.javaClass.simpleName}",
            )
        }
    }

    fun cancel(context: Context) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            ?: return
        manager.cancel(pendingIntent(context))
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, MidnightReceiver::class.java)
            .setAction(ACTION_RESET)
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
