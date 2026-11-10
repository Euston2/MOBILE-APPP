package com.lockout.lockout.platform

/**
 * Everything the blocking service needs to enforce the limit.
 *
 * Deliberately a plain data class with no Android imports: the decision logic
 * ([BlockPolicy]) is unit tested on the JVM, and the service must be able to
 * answer "would this app be blocked?" without Flutter being alive.
 *
 * The values are pushed from Dart (`LockoutPlatform.setBlockingConfig`) and
 * cached in [BlockingStore] so they survive the app process being killed.
 *
 * Scheduled changes (the "settings apply from the next day" rule) are sent as a
 * complete second configuration. [effectiveAt] picks the active one by clock,
 * so a midnight alarm is an optimisation, not a requirement for correctness.
 */
data class BlockingConfig(
    /** Apps whose combined foreground time counts against the limit today. */
    val monitoredPackages: Set<String>,
    /** Combined daily limit in seconds; 0 means "no limit configured". */
    val dailyLimitSeconds: Int,
    /** Apps that count from [pendingEffectiveAtMs] onwards. */
    val pendingPackages: Set<String> = emptySet(),
    /** Limit that applies from [pendingEffectiveAtMs] onwards (0 = none). */
    val pendingLimitSeconds: Int = 0,
    /** Epoch millis at which the pending configuration takes over. */
    val pendingEffectiveAtMs: Long = 0L,
    /** True once the limit has been hit and until the next reset. */
    val isLocked: Boolean = false,
    /** When the lock was stamped (0 while unlocked). */
    val lockedAtMs: Long = 0L,
    /** Local midnight at which a lock expires, as epoch millis. */
    val nextResetAtMs: Long = 0L,
    /** Recurring hard block from local midnight to 08:00. */
    val overnightLockEnabled: Boolean = false,
    /** End of the one-off study session, or 0 when no session is running. */
    val studyEndsAtMs: Long = 0L,
    /** Daily focus goal in seconds (0 = no goal). */
    val focusGoalSeconds: Int = 0,
    /** Whether missing the daily focus goal should block the selected apps. */
    val focusAutoBlockEnabled: Boolean = false,
    /** Local minute of day (0-1439) at which the missed-goal block starts. */
    val focusCutoffMinuteOfDay: Int = 20 * 60,
    /** Focus seconds already banked for the day starting at [focusDayStartMs]. */
    val focusBaseSeconds: Int = 0,
    /** Local midnight of the day [focusBaseSeconds] belongs to (0 = none). */
    val focusDayStartMs: Long = 0L,
    /** Running focus timer bounds (0 when idle or paused). */
    val focusSessionStartedAtMs: Long = 0L,
    val focusSessionEndsAtMs: Long = 0L,
) {
    /** Configuration that applies at [nowMs]. */
    fun effectiveAt(nowMs: Long): ActiveLimit {
        val pending = pendingEffectiveAtMs > 0L &&
            nowMs >= pendingEffectiveAtMs &&
            pendingLimitSeconds > 0 &&
            pendingPackages.isNotEmpty()
        return if (pending) {
            ActiveLimit(pendingPackages, pendingLimitSeconds)
        } else {
            ActiveLimit(monitoredPackages, dailyLimitSeconds)
        }
    }

    /** True when a goal and automation are configured for selected apps. */
    val hasFocusGoal: Boolean
        get() = focusAutoBlockEnabled &&
            focusGoalSeconds > 0 &&
            monitoredPackages.isNotEmpty()

    /**
     * Focus seconds for the local day containing [nowMs], including the elapsed
     * part of a running timer. This mirrors `focusSecondsForToday` in Dart.
     */
    fun focusSecondsAt(nowMs: Long): Int {
        val todayStart = DayMath.startOfLocalDay(nowMs)
        var total = if (focusDayStartMs == todayStart) focusBaseSeconds else 0
        val start = focusSessionStartedAtMs
        val end = focusSessionEndsAtMs
        if (start > 0L && end > start) {
            val from = maxOf(start, todayStart)
            val to = minOf(nowMs, end)
            if (to > from) total += ((to - from) / 1000L).toInt()
        }
        return total
    }

    /**
     * Focus seconds inside an arbitrary archived window.
     *
     * Used by the midnight archive: the day's banked total plus any running
     * timer portion that overlapped that finished day.
     */
    fun focusSecondsInRange(startMs: Long, endMs: Long): Int {
        if (endMs <= startMs) return 0
        var total = if (focusDayStartMs == DayMath.startOfLocalDay(startMs)) {
            focusBaseSeconds
        } else {
            0
        }
        val start = focusSessionStartedAtMs
        val end = focusSessionEndsAtMs
        if (start > 0L && end > start) {
            val from = maxOf(start, startMs)
            val to = minOf(end, endMs)
            if (to > from) total += ((to - from) / 1000L).toInt()
        }
        return total
    }

    /** True after the cutoff when the goal is still short. */
    fun isFocusGoalBlockActive(nowMs: Long): Boolean {
        if (!hasFocusGoal) return false
        if (DayMath.minuteOfLocalDay(nowMs) < focusCutoffMinuteOfDay) return false
        return focusSecondsAt(nowMs) < focusGoalSeconds
    }

    /**
     * Only run the service when something is configured, now or from midnight.
     * The pending configuration keeps the watcher alive so a scheduled change
     * takes effect even if Flutter is never opened that day.
     */
    val isActive: Boolean
        get() = (dailyLimitSeconds > 0 && monitoredPackages.isNotEmpty()) ||
            (pendingLimitSeconds > 0 &&
                pendingPackages.isNotEmpty() &&
                pendingEffectiveAtMs > 0L) ||
            (overnightLockEnabled && monitoredPackages.isNotEmpty()) ||
            (studyEndsAtMs > 0L && monitoredPackages.isNotEmpty()) ||
            hasFocusGoal ||
            focusDayStartMs > 0L ||
            focusSessionEndsAtMs > 0L

    /**
     * Whether the watcher still has something to enforce at [nowMs].
     *
     * An expired study session no longer needs the service; the overnight lock
     * stays armed all day so its next 00:00 boundary is ready even if an alarm
     * is delayed.
     */
    fun isActiveAt(nowMs: Long): Boolean {
        val todayStart = DayMath.startOfLocalDay(nowMs)
        val trackingToday = focusDayStartMs == todayStart
        val sessionRunning = focusSessionStartedAtMs > 0L &&
            focusSessionEndsAtMs > nowMs
        return (dailyLimitSeconds > 0 && monitoredPackages.isNotEmpty()) ||
            (pendingLimitSeconds > 0 &&
                pendingPackages.isNotEmpty() &&
                pendingEffectiveAtMs > 0L) ||
            (overnightLockEnabled && monitoredPackages.isNotEmpty()) ||
            (studyEndsAtMs > nowMs && monitoredPackages.isNotEmpty()) ||
            hasFocusGoal ||
            trackingToday ||
            sessionRunning
    }
}

/** The apps and limit that apply at one instant. */
data class ActiveLimit(
    val packages: Set<String>,
    val limitSeconds: Int,
) {
    val isActive: Boolean
        get() = limitSeconds > 0 && packages.isNotEmpty()
}
