package com.lockout.lockout.platform

/** Why the block screen was shown. */
enum class BlockReason(val wireName: String) {
    /** Combined usage reached the configured daily limit. */
    LIMIT_REACHED("limit_reached"),

    /** The limit was hit earlier and the daily lock has not expired yet. */
    LOCKED("locked"),
}

/**
 * Pure "should this app be blocked?" decision.
 *
 * Kept Android-free so it can be exhaustively unit tested on the JVM
 * (`BlockPolicyTest`). The service, the block activity and the overlay all call
 * the same function, so they can never disagree about the state.
 */
object BlockPolicy {

    /**
     * Lock/limit state without looking at the foreground app.
     *
     * Used by [BlockActivity] (which is already on screen because a violation
     * happened) to decide whether it should close itself.
     */
    fun reasonFor(
        config: BlockingConfig,
        usedSecondsToday: Long,
        nowMs: Long,
    ): BlockReason? {
        // A lock only matters until its reset instant. Checking the clock
        // (rather than trusting an alarm) is what makes the lock survive a
        // missed reset, a force-stop or a reboot.
        if (config.isLocked && nowMs < config.nextResetAtMs) {
            return BlockReason.LOCKED
        }
        if (config.dailyLimitSeconds > 0 && usedSecondsToday >= config.dailyLimitSeconds) {
            return BlockReason.LIMIT_REACHED
        }
        return null
    }

    /**
     * Full check for the foreground service: only monitored apps can be
     * blocked, and only when [reasonFor] says there is something to enforce.
     */
    fun reasonForForeground(
        foregroundPackage: String?,
        config: BlockingConfig,
        usedSecondsToday: Long,
        nowMs: Long,
    ): BlockReason? {
        val pkg = foregroundPackage ?: return null
        if (pkg !in config.monitoredPackages) return null
        return reasonFor(config, usedSecondsToday, nowMs)
    }
}
