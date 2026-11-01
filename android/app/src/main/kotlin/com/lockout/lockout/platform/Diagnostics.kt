package com.lockout.lockout.platform

import android.content.Context
import android.os.Build
import android.os.PowerManager

/**
 * Read-only snapshot for the Protection check screen.
 *
 * It combines the OS permission state, the enforcement config cached by the
 * service, and the bounded event log. Nothing here changes state, so opening the
 * screen cannot affect blocking. The device model is included only to choose the
 * right OEM instructions; the report is copied on demand by the user.
 */
object Diagnostics {

    fun snapshot(context: Context): Map<String, Any> {
        val permissions = PermissionController.snapshot(context)
        val config = BlockingStore.load(context)
        val power = context.getSystemService(Context.POWER_SERVICE) as? PowerManager

        return mapOf(
            "manufacturer" to (Build.MANUFACTURER ?: ""),
            "brand" to (Build.BRAND ?: ""),
            "model" to (Build.MODEL ?: ""),
            "sdkInt" to Build.VERSION.SDK_INT,
            "usageAccess" to (permissions["usageAccess"] == true),
            "overlay" to (permissions["overlay"] == true),
            "notifications" to (permissions["notifications"] == true),
            "batteryOptimizationIgnored" to
                (permissions["batteryOptimizationIgnored"] == true),
            "exactAlarmsAllowed" to MidnightAlarm.canScheduleExact(context),
            "powerSaveMode" to (power?.isPowerSaveMode == true),
            "serviceConfigured" to config.isActive,
            "isLocked" to config.isLocked,
            "lockedAtMs" to config.lockedAtMs,
            "nextResetAtMs" to config.nextResetAtMs,
            "limitSeconds" to config.dailyLimitSeconds,
            "monitoredCount" to config.monitoredPackages.size,
            "pendingConfigured" to (
                config.pendingLimitSeconds > 0 &&
                    config.pendingPackages.isNotEmpty() &&
                    config.pendingEffectiveAtMs > 0L
                ),
            "lastArchivedDate" to (ArchiveStore.lastArchivedDate(context) ?: ""),
            "events" to LockoutLog.read(context).map { entry ->
                mapOf(
                    "timestampMs" to entry.timestampMs,
                    "level" to entry.level,
                    "message" to entry.message,
                )
            },
        )
    }
}
