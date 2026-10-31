package com.lockout.lockout.platform

import android.content.Context

/**
 * Combined foreground seconds today for the monitored apps.
 *
 * Reuses [UsageStatsReader], so the native service and the Flutter Home screen
 * arrive at the limit from the identical event window (local midnight → now).
 * Day arithmetic lives in [DayMath] so it can be unit tested without Android.
 */
object BlockUsage {

    fun usedSecondsToday(
        context: Context,
        nowMs: Long,
        monitoredPackages: Set<String>,
    ): Long = secondsInWindow(
        context,
        startMs = DayMath.startOfLocalDay(nowMs),
        endMs = nowMs,
        packages = monitoredPackages,
    ).values.sum().toLong()

    /** Per-package seconds in an explicit window, filtered to [packages]. */
    fun secondsByPackage(
        context: Context,
        startMs: Long,
        endMs: Long,
        packages: Set<String>,
    ): Map<String, Int> = secondsInWindow(context, startMs, endMs, packages)

    /** Local 00:00 for [nowMs], matching `startOfLocalDay` on the Dart side. */
    fun startOfLocalDay(nowMs: Long): Long = DayMath.startOfLocalDay(nowMs)

    /** Local 00:00 of the previous day (DST-safe via Calendar). */
    fun startOfPreviousLocalDay(nowMs: Long): Long =
        DayMath.startOfPreviousLocalDay(nowMs)

    /** Next local 00:00 strictly after [nowMs]. */
    fun nextLocalMidnight(nowMs: Long): Long = DayMath.nextLocalMidnight(nowMs)

    /** Local date key (`yyyy-MM-dd`) used by the archive and the drift tables. */
    fun localDate(nowMs: Long): String = DayMath.localDate(nowMs)

    private fun secondsInWindow(
        context: Context,
        startMs: Long,
        endMs: Long,
        packages: Set<String>,
    ): Map<String, Int> {
        if (packages.isEmpty() || endMs <= startMs) return emptyMap()

        val raw = UsageStatsReader.read(context, startMs, endMs)
        val apps = raw["apps"] as? List<*> ?: return emptyMap()
        val result = LinkedHashMap<String, Int>()
        for (item in apps) {
            val app = item as? Map<*, *> ?: continue
            val packageName = app["packageName"] as? String ?: continue
            if (packageName !in packages) continue
            val seconds = ((app["millis"] as? Long ?: 0L) / 1000L).toInt()
            if (seconds > 0) result[packageName] = seconds
        }
        return result
    }
}
