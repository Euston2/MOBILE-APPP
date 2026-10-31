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

    fun scheduleAt(context: Context, atMs: Long) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            ?: return
        val target = maxOf(atMs, System.currentTimeMillis() + 1_000L)

        try {
            val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                manager.canScheduleExactAlarms()
            if (canExact) {
                manager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    target,
                    pendingIntent(context),
                )
            } else {
                manager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    target,
                    pendingIntent(context),
                )
            }
        } catch (_: SecurityException) {
            // Exact-alarm access can be revoked between the check and the call.
            manager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                target,
                pendingIntent(context),
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
