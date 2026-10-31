package com.lockout.lockout.platform

import android.content.Context

/**
 * Stamps and clears the persisted daily lock.
 *
 * The lock exists so changing or removing the limit cannot unblock an app after
 * the limit was hit: the decision is "is it locked?", not "is usage still high?".
 * It is written in two places, atomically enough for enforcement:
 * - [BlockingStore], which the service and block surfaces read;
 * - Flutter's prefs (via [FlutterSettings]), which the UI reads after reload.
 */
object LockState {

    /**
     * Stamps a lock at [nowMs] and arms the midnight alarm.
     *
     * No-op when a valid lock is already present, so the 2-second poll cannot
     * move the original `locked_at` timestamp.
     */
    fun lock(context: Context, config: BlockingConfig, nowMs: Long): BlockingConfig {
        if (config.isLocked && nowMs < config.nextResetAtMs) return config

        val resetAtMs = DayMath.nextLocalMidnight(nowMs)
        val locked = config.copy(
            isLocked = true,
            lockedAtMs = nowMs,
            nextResetAtMs = resetAtMs,
        )
        BlockingStore.saveLock(context, locked)
        FlutterSettings.writeLock(context, true, nowMs, resetAtMs)
        MidnightAlarm.scheduleNext(context, nowMs)
        return locked
    }

    /** Clears an expired lock while keeping the rest of the configuration. */
    fun clear(context: Context, config: BlockingConfig, nowMs: Long): BlockingConfig {
        val resetAtMs = DayMath.nextLocalMidnight(nowMs)
        val cleared = config.copy(
            isLocked = false,
            lockedAtMs = 0L,
            nextResetAtMs = resetAtMs,
        )
        BlockingStore.saveLock(context, cleared)
        FlutterSettings.writeLock(context, false, 0L, resetAtMs)
        return cleared
    }
}
