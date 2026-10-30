package com.lockout.lockout.platform

import android.content.Context

/**
 * Caches the latest [BlockingConfig] in the service's own shared preferences.
 *
 * Why not read Flutter's `shared_preferences` file directly? Its key prefix and
 * encoding are plugin implementation details, and the monitored-app list lives
 * in drift/SQLite. Mirroring the config into a private file keeps the native
 * layer independent of how Dart stores things, and lets the service keep
 * enforcing the limit when the Flutter engine is not running.
 */
object BlockingStore {

    private const val PREFS_NAME = "lockout_blocking"
    private const val KEY_PACKAGES = "monitored_packages"
    private const val KEY_LIMIT = "daily_limit_seconds"
    private const val KEY_LOCKED = "is_locked"
    private const val KEY_RESET_AT = "next_reset_at_ms"

    fun load(context: Context): BlockingConfig {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return BlockingConfig(
            monitoredPackages = prefs.getStringSet(KEY_PACKAGES, emptySet())
                ?.toSet()
                ?: emptySet(),
            dailyLimitSeconds = prefs.getInt(KEY_LIMIT, 0),
            isLocked = prefs.getBoolean(KEY_LOCKED, false),
            nextResetAtMs = prefs.getLong(KEY_RESET_AT, 0L),
        )
    }

    fun save(context: Context, config: BlockingConfig) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putStringSet(KEY_PACKAGES, config.monitoredPackages)
            .putInt(KEY_LIMIT, config.dailyLimitSeconds)
            .putBoolean(KEY_LOCKED, config.isLocked)
            .putLong(KEY_RESET_AT, config.nextResetAtMs)
            .apply()
    }
}
