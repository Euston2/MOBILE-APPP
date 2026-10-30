package com.lockout.lockout.platform

import android.content.Context
import java.util.Calendar

/**
 * Combined foreground seconds today for the monitored apps.
 *
 * Reuses [UsageStatsReader], so the native service and the Flutter Home screen
 * arrive at the limit from the identical event window (local midnight → now).
 */
object BlockUsage {

    fun usedSecondsToday(
        context: Context,
        nowMs: Long,
        monitoredPackages: Set<String>,
    ): Long {
        if (monitoredPackages.isEmpty()) return 0L

        val raw = UsageStatsReader.read(context, startOfLocalDay(nowMs), nowMs)
        val apps = raw["apps"] as? List<*> ?: return 0L

        var millis = 0L
        for (item in apps) {
            val app = item as? Map<*, *> ?: continue
            val packageName = app["packageName"] as? String ?: continue
            if (packageName !in monitoredPackages) continue
            millis += app["millis"] as? Long ?: 0L
        }
        return millis / 1000L
    }

    /** Local 00:00 for [nowMs], matching `startOfLocalDay` on the Dart side. */
    fun startOfLocalDay(nowMs: Long): Long {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = nowMs
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }
}
