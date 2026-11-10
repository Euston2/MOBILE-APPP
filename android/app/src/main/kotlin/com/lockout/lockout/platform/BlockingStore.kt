package com.lockout.lockout.platform

import android.content.Context

/**
 * Caches the latest [BlockingConfig] in the service's own shared preferences.
 *
 * Why keep a private copy instead of reading Flutter's prefs? The monitored-app
 * list lives in drift/SQLite, and routing all config through one native snapshot
 * keeps the enforcement path independent of the Flutter engine. The lock fields
 * are mirrored into Flutter's prefs by [FlutterSettings] so the UI can show the
 * lock without an extra channel round-trip.
 */
object BlockingStore {

    private const val PREFS_NAME = "lockout_blocking"
    private const val KEY_PACKAGES = "monitored_packages"
    private const val KEY_LIMIT = "daily_limit_seconds"
    private const val KEY_PENDING_PACKAGES = "pending_packages"
    private const val KEY_PENDING_LIMIT = "pending_limit_seconds"
    private const val KEY_PENDING_EFFECTIVE_AT = "pending_effective_at_ms"
    private const val KEY_LOCKED = "is_locked"
    private const val KEY_LOCKED_AT = "locked_at_ms"
    private const val KEY_RESET_AT = "next_reset_at_ms"
    private const val KEY_OVERNIGHT_LOCK = "overnight_lock_enabled"
    private const val KEY_STUDY_ENDS_AT = "study_ends_at_ms"
    private const val KEY_FOCUS_GOAL_SECONDS = "focus_goal_seconds"
    private const val KEY_FOCUS_AUTO_BLOCK = "focus_auto_block_enabled"
    private const val KEY_FOCUS_CUTOFF_MINUTE = "focus_cutoff_minute_of_day"
    private const val KEY_FOCUS_BASE_SECONDS = "focus_base_seconds"
    private const val KEY_FOCUS_DAY_START = "focus_day_start_ms"
    private const val KEY_FOCUS_SESSION_START = "focus_session_started_at_ms"
    private const val KEY_FOCUS_SESSION_END = "focus_session_ends_at_ms"

    fun load(context: Context): BlockingConfig {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return BlockingConfig(
            monitoredPackages = prefs.getStringSet(KEY_PACKAGES, emptySet())
                ?.toSet()
                ?: emptySet(),
            dailyLimitSeconds = prefs.getInt(KEY_LIMIT, 0),
            pendingPackages = prefs.getStringSet(KEY_PENDING_PACKAGES, emptySet())
                ?.toSet()
                ?: emptySet(),
            pendingLimitSeconds = prefs.getInt(KEY_PENDING_LIMIT, 0),
            pendingEffectiveAtMs = prefs.getLong(KEY_PENDING_EFFECTIVE_AT, 0L),
            isLocked = prefs.getBoolean(KEY_LOCKED, false),
            lockedAtMs = prefs.getLong(KEY_LOCKED_AT, 0L),
            nextResetAtMs = prefs.getLong(KEY_RESET_AT, 0L),
            overnightLockEnabled = prefs.getBoolean(KEY_OVERNIGHT_LOCK, false),
            studyEndsAtMs = prefs.getLong(KEY_STUDY_ENDS_AT, 0L),
            focusGoalSeconds = prefs.getInt(KEY_FOCUS_GOAL_SECONDS, 0),
            focusAutoBlockEnabled = prefs.getBoolean(KEY_FOCUS_AUTO_BLOCK, false),
            focusCutoffMinuteOfDay = prefs.getInt(
                KEY_FOCUS_CUTOFF_MINUTE,
                20 * 60,
            ),
            focusBaseSeconds = prefs.getInt(KEY_FOCUS_BASE_SECONDS, 0),
            focusDayStartMs = prefs.getLong(KEY_FOCUS_DAY_START, 0L),
            focusSessionStartedAtMs = prefs.getLong(KEY_FOCUS_SESSION_START, 0L),
            focusSessionEndsAtMs = prefs.getLong(KEY_FOCUS_SESSION_END, 0L),
        )
    }

    fun save(context: Context, config: BlockingConfig) {
        // commit(), not apply(): a config push is followed immediately by a
        // foreground-service start, and the process can be killed before an
        // asynchronous disk write lands. Losing this snapshot would drop the
        // saved daily limit on the next service restart.
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putStringSet(KEY_PACKAGES, config.monitoredPackages)
            .putInt(KEY_LIMIT, config.dailyLimitSeconds)
            .putStringSet(KEY_PENDING_PACKAGES, config.pendingPackages)
            .putInt(KEY_PENDING_LIMIT, config.pendingLimitSeconds)
            .putLong(KEY_PENDING_EFFECTIVE_AT, config.pendingEffectiveAtMs)
            .putBoolean(KEY_LOCKED, config.isLocked)
            .putLong(KEY_LOCKED_AT, config.lockedAtMs)
            .putLong(KEY_RESET_AT, config.nextResetAtMs)
            .putBoolean(KEY_OVERNIGHT_LOCK, config.overnightLockEnabled)
            .putLong(KEY_STUDY_ENDS_AT, config.studyEndsAtMs)
            .putInt(KEY_FOCUS_GOAL_SECONDS, config.focusGoalSeconds)
            .putBoolean(KEY_FOCUS_AUTO_BLOCK, config.focusAutoBlockEnabled)
            .putInt(KEY_FOCUS_CUTOFF_MINUTE, config.focusCutoffMinuteOfDay)
            .putInt(KEY_FOCUS_BASE_SECONDS, config.focusBaseSeconds)
            .putLong(KEY_FOCUS_DAY_START, config.focusDayStartMs)
            .putLong(KEY_FOCUS_SESSION_START, config.focusSessionStartedAtMs)
            .putLong(KEY_FOCUS_SESSION_END, config.focusSessionEndsAtMs)
            .commit()
    }

    /** Persists the lock immediately; the service may be killed right after. */
    fun saveLock(context: Context, config: BlockingConfig) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_LOCKED, config.isLocked)
            .putLong(KEY_LOCKED_AT, config.lockedAtMs)
            .putLong(KEY_RESET_AT, config.nextResetAtMs)
            .commit()
    }
}
