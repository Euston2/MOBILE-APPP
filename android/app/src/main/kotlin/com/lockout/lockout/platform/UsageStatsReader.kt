package com.lockout.lockout.platform

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context

/**
 * Reads today's foreground time from [UsageStatsManager].
 *
 * `UsageStatsManager.queryUsageStats()` returns per-bucket totals that are not
 * clipped to an arbitrary window and drift across midnight, so Lockout uses
 * `queryEvents()` instead: resume/pause/lock events give us exact intervals
 * that [UsageAggregator] can clip to "since 00:00".
 *
 * Requires the `PACKAGE_USAGE_STATS` special access (the user grants it in
 * Settings). Without it the query simply returns no events.
 */
object UsageStatsReader {

    /**
     * Events are queried from before the window start so an app that was already
     * in the foreground at 00:00 is counted from midnight rather than from its
     * next resume. The lookback is bounded to keep the query cheap.
     */
    private const val LOOKBACK_MS = 24L * 60L * 60L * 1000L

    /**
     * @return `{ startMs, endMs, apps: [{ packageName, millis }] }` sorted by
     *   descending usage, ready to be decoded by the Dart layer.
     */
    fun read(context: Context, windowStartMs: Long, windowEndMs: Long): Map<String, Any> {
        val manager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return mapOf<String, Any>(
                "startMs" to windowStartMs,
                "endMs" to windowEndMs,
                "apps" to emptyList<Map<String, Any>>(),
            )

        val events = ArrayList<UsageEvent>()
        val cursor = manager.queryEvents(windowStartMs - LOOKBACK_MS, windowEndMs)
        val event = UsageEvents.Event()

        while (cursor.hasNextEvent()) {
            cursor.getNextEvent(event)
            val type = when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> UsageAggregator.RESUMED
                UsageEvents.Event.ACTIVITY_PAUSED -> UsageAggregator.PAUSED
                UsageEvents.Event.SCREEN_NON_INTERACTIVE,
                UsageEvents.Event.KEYGUARD_SHOWN,
                UsageEvents.Event.DEVICE_SHUTDOWN,
                -> UsageAggregator.INTERRUPTED
                else -> continue
            }
            val pkg = event.packageName ?: ""
            // Screen-off events carry no package; they only close the segment.
            if (type != UsageAggregator.INTERRUPTED && pkg.isEmpty()) continue
            events.add(UsageEvent(timestampMs = event.timeStamp, type = type, packageName = pkg))
        }

        val millisByPackage = UsageAggregator.aggregate(events, windowStartMs, windowEndMs)
        val apps = millisByPackage.entries
            .sortedByDescending { it.value }
            .map { mapOf<String, Any>("packageName" to it.key, "millis" to it.value) }

        return mapOf("startMs" to windowStartMs, "endMs" to windowEndMs, "apps" to apps)
    }
}
