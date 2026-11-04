package com.lockout.lockout.platform

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

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
        BlockReason.OVERNIGHT -> "Overnight lock"
        BlockReason.STUDY -> "Study time"
    }

    fun detail(
        reason: BlockReason,
        usedSeconds: Long,
        limitSeconds: Long,
        studyEndsAtMs: Long = 0L,
    ): String = when (reason) {
        BlockReason.LIMIT_REACHED ->
            "You have used ${formatDuration(usedSeconds)} of your " +
                "${formatDuration(limitSeconds)} daily limit."
        BlockReason.LOCKED ->
            "Your ${formatDuration(limitSeconds)} daily limit is locked. " +
                "You had used ${formatDuration(usedSeconds)} when it was hit."
        BlockReason.OVERNIGHT ->
            "Your selected apps are blocked every night from 12:00 AM to " +
                "8:00 AM. They will open again after 8:00 AM."
        BlockReason.STUDY ->
            "Your study lock is on" +
                if (studyEndsAtMs > 0L) {
                    " until ${formatTime(studyEndsAtMs)}. "
                } else {
                    ". "
                } +
                "Selected apps stay blocked until the session ends."
    }

    /** Local clock label used by the study block screen. */
    fun formatTime(epochMs: Long): String =
        SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date(epochMs))

    const val FOOTER = "Lockout enforces your chosen limits and focus times. " +
        "The block closes automatically when the time is up."
}
