package com.lockout.lockout.platform

/** Why the block screen was shown. */
enum class BlockReason(val wireName: String) {
    /** Combined usage reached the configured daily limit. */
    LIMIT_REACHED("limit_reached"),

    /** The limit was hit earlier and the daily lock has not expired yet. */
    LOCKED("locked"),

    /** The fixed 00:00-08:00 overnight focus window is active. */
    OVERNIGHT("overnight"),

    /** A one-off study session is running. */
    STUDY("study"),

    /** The daily focus goal was missed and the cutoff has passed. */
    FOCUS_GOAL_MISSED("focus_goal_missed"),
}

/**
 * Pure "should this app be blocked?" decision.
 *
 * Kept Android-free so it can be exhaustively unit tested on the JVM
 * (`BlockPolicyTest`). The service, the block activity and the overlay all call
 * the same function, so they can never disagree about the state.
 *
 * All checks resolve the effective configuration for the supplied clock value,
 * which is how a limit/app change saved before midnight starts applying at
 * 00:00 without any Dart call.
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
        val active = config.effectiveAt(nowMs)

        // Focus locks are hard time windows, independent of today's usage.
        // They only apply when there is at least one selected app.
        if (active.packages.isNotEmpty()) {
            if (config.studyEndsAtMs > nowMs) return BlockReason.STUDY
            if (
                config.overnightLockEnabled &&
                DayMath.isInOvernightWindow(nowMs)
            ) {
                return BlockReason.OVERNIGHT
            }
            if (config.isFocusGoalBlockActive(nowMs)) {
                return BlockReason.FOCUS_GOAL_MISSED
            }
        }

        // A lock only matters until its reset instant. Checking the clock
        // (rather than trusting an alarm) is what makes the lock survive a
        // missed reset, a force-stop or a reboot.
        if (config.isLocked && nowMs < config.nextResetAtMs) {
            return BlockReason.LOCKED
        }

        if (active.limitSeconds > 0 && usedSecondsToday >= active.limitSeconds) {
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
        if (pkg !in config.effectiveAt(nowMs).packages) return null
        return reasonFor(config, usedSecondsToday, nowMs)
    }

    /**
     * True when the limit has just been crossed and no lock has been stamped
     * yet. The service calls [LockState.lock] when this returns true, which
     * turns "usage is currently high" into a persisted lock until midnight.
     */
    fun shouldLock(
        config: BlockingConfig,
        usedSecondsToday: Long,
        nowMs: Long,
    ): Boolean {
        if (config.isLocked && nowMs < config.nextResetAtMs) return false
        val active = config.effectiveAt(nowMs)
        return active.limitSeconds > 0 &&
            usedSecondsToday >= active.limitSeconds
    }
}
