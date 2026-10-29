package com.lockout.lockout.platform

/**
 * Pure Kotlin implementation of the "time used today" calculation.
 *
 * Kept free of Android imports so it can be unit tested on the JVM
 * (`android/app/src/test/.../UsageAggregatorTest.kt`). The Android-specific
 * event parsing lives in [UsageStatsReader].
 *
 * Algorithm: walk the usage events in order, keeping track of the package that
 * is currently in the foreground and since when. Every time the foreground
 * package changes (resume of another app, pause, screen off, end of window) the
 * open segment is closed and added to the totals. Segments are clipped to the
 * requested window so an app opened before midnight is counted only from 00:00.
 */
object UsageAggregator {

    const val RESUMED = 1L

    const val PAUSED = 2L

    /** Screen locked/off or device shutting down: nothing is in the foreground. */
    const val INTERRUPTED = 3L

    /**
     * @param events usage events, any order; only those at or before [windowEndMs]
     *   are considered.
     * @param windowStartMs start of the counting window (local 00:00).
     * @param windowEndMs end of the counting window (usually "now").
     * @return foreground duration in milliseconds per package.
     */
    fun aggregate(
        events: List<UsageEvent>,
        windowStartMs: Long,
        windowEndMs: Long,
    ): Map<String, Long> {
        if (windowEndMs <= windowStartMs) return emptyMap()

        val ordered = events
            .filter { it.timestampMs <= windowEndMs }
            .sortedBy { it.timestampMs }

        val totals = HashMap<String, Long>()
        var currentPackage: String? = null
        var segmentStartMs = 0L

        fun closeSegment(atMs: Long) {
            val pkg = currentPackage ?: return
            val from = maxOf(segmentStartMs, windowStartMs)
            val to = minOf(atMs, windowEndMs)
            if (to > from) {
                totals[pkg] = (totals[pkg] ?: 0L) + (to - from)
            }
            currentPackage = null
        }

        for (event in ordered) {
            when (event.type) {
                RESUMED -> {
                    // A resume without a matching pause means the previous app
                    // was left by switching directly: close it at this instant.
                    // A repeat resume for the same package (Android emits these
                    // when an activity is re-created) keeps the original start.
                    if (currentPackage != event.packageName) {
                        if (currentPackage != null) closeSegment(event.timestampMs)
                        currentPackage = event.packageName
                        segmentStartMs = event.timestampMs
                    }
                }

                PAUSED -> {
                    if (currentPackage == event.packageName) closeSegment(event.timestampMs)
                }

                INTERRUPTED -> closeSegment(event.timestampMs)
            }
        }

        // Still open when the window ends (e.g. the app is in the foreground now).
        closeSegment(windowEndMs)
        return totals
    }
}

/**
 * A single foreground event, decoupled from `android.app.usage.UsageEvents`.
 *
 * @param type one of [UsageAggregator.RESUMED], [UsageAggregator.PAUSED],
 *   [UsageAggregator.INTERRUPTED].
 */
data class UsageEvent(
    val timestampMs: Long,
    val type: Long,
    val packageName: String,
)
