package com.lockout.lockout.platform

import android.content.Context

/**
 * Mirrors lock fields into Flutter's `shared_preferences` file.
 *
 * The lock is stamped while another app is in the foreground, often with no
 * Flutter engine running, so Kotlin cannot call a Dart setter. Both layers need
 * one truth: the service writes `is_locked` / `locked_at` / `next_reset_at`
 * directly into the prefs file that `shared_preferences` reads. Dart calls
 * `SharedPreferences.reload()` when the app resumes (see
 * `PrefsSettingsRepository.reload`).
 *
 * The file name, `flutter.` key prefix and long encoding are stable in the
 * pinned `shared_preferences_android` version (the legacy API intentionally
 * keeps them for backwards compatibility). If the plugin is ever replaced, only
 * this object needs to change.
 */
object FlutterSettings {

    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_PREFIX = "flutter."

    private const val KEY_IS_LOCKED = KEY_PREFIX + "settings.is_locked"
    private const val KEY_LOCKED_AT = KEY_PREFIX + "settings.locked_at"
    private const val KEY_NEXT_RESET_AT = KEY_PREFIX + "settings.next_reset_at"
    private const val KEY_DAILY_LIMIT = KEY_PREFIX + "settings.daily_limit_seconds"
    private const val KEY_PENDING_LIMIT =
        KEY_PREFIX + "settings.pending_limit_seconds"
    private const val KEY_PENDING_EFFECTIVE_AT =
        KEY_PREFIX + "settings.pending_effective_at"

    /**
     * Mirrors a native limit change into Flutter's cache.
     *
     * Used by the 5-minute notification action and by the midnight
     * materialisation of a scheduled limit. `pending` is null when there is no
     * scheduled change, in which case its keys are removed so a stale pending
     * value cannot overwrite the native limit when Dart next reconciles.
     */
    fun writeLimits(
        context: Context,
        dailyLimitSeconds: Int,
        pendingLimitSeconds: Int?,
        pendingEffectiveAtMs: Long?,
    ) {
        val editor = context
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putLong(KEY_DAILY_LIMIT, dailyLimitSeconds.toLong())

        if (pendingLimitSeconds != null &&
            pendingLimitSeconds > 0 &&
            pendingEffectiveAtMs != null &&
            pendingEffectiveAtMs > 0L
        ) {
            editor.putLong(KEY_PENDING_LIMIT, pendingLimitSeconds.toLong())
            editor.putLong(KEY_PENDING_EFFECTIVE_AT, pendingEffectiveAtMs)
        } else {
            editor.remove(KEY_PENDING_LIMIT)
            editor.remove(KEY_PENDING_EFFECTIVE_AT)
        }
        editor.commit()
    }

    /** Writes a lock (or its clearing) and commits before the process can die. */
    fun writeLock(
        context: Context,
        isLocked: Boolean,
        lockedAtMs: Long,
        nextResetAtMs: Long,
    ) {
        val editor = context
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_IS_LOCKED, isLocked)

        if (isLocked) {
            // shared_preferences stores Dart ints as Java longs.
            editor.putLong(KEY_LOCKED_AT, lockedAtMs)
        } else {
            editor.remove(KEY_LOCKED_AT)
        }
        if (nextResetAtMs > 0L) {
            editor.putLong(KEY_NEXT_RESET_AT, nextResetAtMs)
        }
        editor.commit()
    }
}
