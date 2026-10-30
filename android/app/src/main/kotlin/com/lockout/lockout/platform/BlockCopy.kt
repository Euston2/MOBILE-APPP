package com.lockout.lockout.platform

/**
 * Human-readable durations for the native block screen, notification and
 * overlay.
 *
 * Mirrors `lib/core/utils/duration_format.dart` so the number the user sees on
 * the Flutter Home screen is the same one shown when an app is blocked.
 * Kept pure for JVM tests.
 */
object BlockCopy {

    fun formatDuration(seconds: Long): String {
        val safe = if (seconds < 0) 0 else seconds
        if (safe == 0L) return "0m"
        if (safe < 60) return "<1m"

        val hours = safe / 3600
        val minutes = (safe % 3600) / 60

        return when {
            hours == 0L -> "${minutes}m"
            minutes == 0L -> "${hours}h"
            else -> "${hours}h ${minutes.toString().padStart(2, '0')}m"
        }
    }

    fun title(reason: BlockReason): String = when (reason) {
        BlockReason.LIMIT_REACHED -> "Time's up"
        BlockReason.LOCKED -> "Locked until midnight"
    }

    fun detail(reason: BlockReason, usedSeconds: Long, limitSeconds: Long): String =
        when (reason) {
            BlockReason.LIMIT_REACHED ->
                "You have used ${formatDuration(usedSeconds)} of your " +
                    "${formatDuration(limitSeconds)} daily limit."
            BlockReason.LOCKED ->
                "Your ${formatDuration(limitSeconds)} daily limit is locked. " +
                    "You had used ${formatDuration(usedSeconds)} when it was hit."
        }

    const val FOOTER = "Monitored apps stay blocked until 00:00. " +
        "The counter resets automatically."
}
