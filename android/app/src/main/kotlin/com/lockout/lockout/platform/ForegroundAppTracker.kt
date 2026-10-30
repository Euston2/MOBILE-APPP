package com.lockout.lockout.platform

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.PowerManager

/**
 * Tracks which package is currently in the foreground.
 *
 * `UsageStatsManager` has no "current app" API, so we follow the event stream:
 * the last resume wins, and a pause of the tracked package clears it. Events are
 * read incrementally (a short lookback on every poll), with a wider first scan
 * so a service started while an app is already open still knows where it is.
 *
 * A screen-off or locked device reports no foreground app. That matters: without
 * it, the service would keep "seeing" the last app and show the block screen
 * while the phone sits in a pocket.
 */
class ForegroundAppTracker {

    private var currentPackage: String? = null
    private var initialised = false

    fun currentPackage(context: Context, nowMs: Long): String? {
        if (!isInteractive(context)) {
            currentPackage = null
            return null
        }

        val manager = context.getSystemService(Context.USAGE_STATS_SERVICE)
            as? UsageStatsManager ?: return currentPackage

        val lookback = if (initialised) POLL_LOOKBACK_MS else INITIAL_LOOKBACK_MS
        val cursor = manager.queryEvents(nowMs - lookback, nowMs)
        val event = UsageEvents.Event()

        while (cursor.hasNextEvent()) {
            cursor.getNextEvent(event)
            when (event.eventType) {
                // ACTIVITY_RESUMED is the post-API-29 name for MOVE_TO_FOREGROUND
                // (same value), so this works on every supported version.
                UsageEvents.Event.ACTIVITY_RESUMED -> currentPackage = event.packageName
                UsageEvents.Event.ACTIVITY_PAUSED -> {
                    if (currentPackage == event.packageName) currentPackage = null
                }
            }
        }

        initialised = true
        return currentPackage
    }

    private fun isInteractive(context: Context): Boolean {
        val power = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            ?: return true
        return power.isInteractive
    }

    private companion object {
        /** Normal poll window; generously larger than the 2 s poll interval. */
        const val POLL_LOOKBACK_MS = 30_000L

        /** First scan after the service starts, to find an already-open app. */
        const val INITIAL_LOOKBACK_MS = 12L * 60L * 60L * 1000L
    }
}
