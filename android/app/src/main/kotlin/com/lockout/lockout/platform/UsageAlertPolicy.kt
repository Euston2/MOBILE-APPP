package com.lockout.lockout.platform

/**
 * Pure rules for the remaining-time notifications.
 *
 * Four warnings are sent as the daily allowance approaches its end. The 5-minute
 * warning is the only one that offers the native "+10 minutes" action.
 *
 * The rules are deliberately separate from Android so the threshold crossings
 * and the once-per-threshold guarantee can be tested on the JVM.
 */
object UsageAlertPolicy {

    const val ONE_HOUR_SECONDS = 60 * 60
    const val THIRTY_MINUTES_SECONDS = 30 * 60
    const val FIFTEEN_MINUTES_SECONDS = 15 * 60
    const val FIVE_MINUTES_SECONDS = 5 * 60

    /** Time added by the notification action, in seconds. */
    const val EXTENSION_SECONDS = 10 * 60

    /** Descending so the most urgent crossed warning is the last match. */
    val thresholds = intArrayOf(
        ONE_HOUR_SECONDS,
        THIRTY_MINUTES_SECONDS,
        FIFTEEN_MINUTES_SECONDS,
        FIVE_MINUTES_SECONDS,
    )

    /** Remaining seconds, never negative. A missing limit has no warnings. */
    fun remainingSeconds(limitSeconds: Int, usedSeconds: Long): Int {
        if (limitSeconds <= 0) return 0
        val remaining = limitSeconds.toLong() - usedSeconds
        return if (remaining <= 0L) 0 else remaining.toInt()
    }

    /**
     * The warning tier that best describes [remainingSeconds].
     *
     * Returning the *smallest* threshold at or above the remaining time means
     * 20 minutes maps to the 30-minute warning, not the old 1-hour one.
     */
    fun tierFor(remainingSeconds: Int): Int? =
        thresholds.lastOrNull { remainingSeconds <= it }

    /**
     * The most urgent warning crossed between two checks, or null when the
     * allowance did not move down past a threshold.
     */
    fun crossedThreshold(
        previousRemainingSeconds: Int,
        currentRemainingSeconds: Int,
    ): Int? {
        if (currentRemainingSeconds >= previousRemainingSeconds) return null
        return thresholds.lastOrNull { threshold ->
            previousRemainingSeconds > threshold &&
                currentRemainingSeconds <= threshold
        }
    }

    /**
     * On a fresh service start, warn immediately when the allowance is at or
     * below five minutes, or exactly on a threshold. The exact-threshold case
     * covers a limit that starts at 1h/30m/15m/5m, where the first check would
     * otherwise never observe a downward crossing. Older, already-passed tiers
     * stay suppressed so a restarted watcher does not replay them.
     */
    fun shouldNotifyOnFreshStart(remainingSeconds: Int): Boolean =
        remainingSeconds in 1..FIVE_MINUTES_SECONDS ||
            remainingSeconds in thresholds

    /**
     * Mask containing every threshold at or above the current remaining time.
     * Marking those as "passed" prevents a burst of old warnings after a
     * restart or a missed poll.
     */
    fun markPassed(mask: Int, remainingSeconds: Int): Int {
        var result = mask
        for (threshold in thresholds) {
            if (remainingSeconds <= threshold) {
                result = result or bitFor(threshold)
            }
        }
        return result
    }

    fun bitFor(thresholdSeconds: Int): Int = when (thresholdSeconds) {
        ONE_HOUR_SECONDS -> 1
        THIRTY_MINUTES_SECONDS -> 1 shl 1
        FIFTEEN_MINUTES_SECONDS -> 1 shl 2
        FIVE_MINUTES_SECONDS -> 1 shl 3
        else -> 0
    }

    fun hasNotified(mask: Int, thresholdSeconds: Int): Boolean =
        (mask and bitFor(thresholdSeconds)) != 0

    /**
     * The notification title. The 5-minute warning is intentionally action
     * oriented because it carries the only native bypass.
     */
    fun titleFor(thresholdSeconds: Int): String = when (thresholdSeconds) {
        ONE_HOUR_SECONDS -> "1 hour left"
        THIRTY_MINUTES_SECONDS -> "30 minutes left"
        FIFTEEN_MINUTES_SECONDS -> "15 minutes left"
        FIVE_MINUTES_SECONDS -> "5 minutes left"
        else -> "Time is running out"
    }

    /** Body copy; [remainingSeconds] is the live value, which can be lower. */
    fun bodyFor(
        thresholdSeconds: Int,
        remainingSeconds: Int,
        appCount: Int,
    ): String {
        val length = BlockCopy.formatDuration(remainingSeconds.toLong())
        val apps = "$appCount ${if (appCount == 1) "app" else "apps"}"
        return if (thresholdSeconds == FIVE_MINUTES_SECONDS) {
            "$length left across $apps. Add 10 minutes right here, or open " +
                "Lockout to review your limit."
        } else {
            "$length left across $apps today. Lockout will block them when " +
                "the allowance reaches zero."
        }
    }
}
