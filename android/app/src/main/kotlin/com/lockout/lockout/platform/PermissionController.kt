package com.lockout.lockout.platform

import android.Manifest
import android.app.Activity
import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings

/**
 * Reads and opens Settings screens for the four special permissions Lockout
 * needs. All of them are user-granted "special access" — an app cannot grant
 * them to itself, so each helper deep-links to the matching system screen.
 */
object PermissionController {

    /**
     * @return `{ usageAccess, overlay, notifications, batteryOptimizationIgnored }`
     */
    fun snapshot(context: Context): Map<String, Boolean> = mapOf(
        "usageAccess" to hasUsageAccess(context),
        "overlay" to Settings.canDrawOverlays(context),
        "notifications" to notificationsEnabled(context),
        "batteryOptimizationIgnored" to isIgnoringBatteryOptimizations(context),
    )

    /**
     * `AppOpsManager` is the only reliable check for usage access; the
     * permission is not a normal runtime permission and `checkSelfPermission`
     * always reports "granted" for it on some ROMs.
     */
    private fun hasUsageAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun notificationsEnabled(context: Context): Boolean {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return false
        val runtimeGranted = Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        return manager.areNotificationsEnabled() && runtimeGranted
    }

    private fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        val power = context.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return false
        return power.isIgnoringBatteryOptimizations(context.packageName)
    }

    fun openUsageAccessSettings(activity: Activity) = launch(
        activity,
        Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS),
    )

    fun openOverlaySettings(activity: Activity) = launch(
        activity,
        Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${activity.packageName}"),
        ),
    )

    fun openNotificationSettings(activity: Activity) {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
        } else {
            appDetailsIntent(activity)
        }
        launch(activity, intent, fallback = appDetailsIntent(activity))
    }

    /**
     * Opens the battery-optimisation exemption prompt. The direct request is
     * restricted by Play policy, so the general list is used as a fallback when
     * the OEM blocks the direct intent.
     */
    fun openBatteryOptimizationSettings(activity: Activity) {
        val direct = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            .setData(Uri.parse("package:${activity.packageName}"))
        val list = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        launch(activity, direct, fallback = list)
    }

    fun openAppDetails(activity: Activity) = launch(activity, appDetailsIntent(activity))

    private fun appDetailsIntent(context: Context): Intent =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.parse("package:${context.packageName}"))

    private fun launch(activity: Activity, intent: Intent, fallback: Intent? = null) {
        try {
            activity.startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            val safe = fallback ?: Intent(Settings.ACTION_SETTINGS)
            try {
                activity.startActivity(safe)
            } catch (_: ActivityNotFoundException) {
                // Nothing left to open; the status row simply stays red.
            }
        }
    }
}
