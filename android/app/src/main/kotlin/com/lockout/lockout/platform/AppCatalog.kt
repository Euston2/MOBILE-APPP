package com.lockout.lockout.platform

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build

/**
 * Lists launchable apps so the user can choose what Lockout should watch.
 *
 * `QUERY_ALL_PACKAGES` is declared in the manifest: on Android 11+ package
 * visibility hides most installed apps from [PackageManager] otherwise. Only
 * package name, label and a system flag are returned — no icon bytes, no
 * account data, nothing leaves the device.
 */
object AppCatalog {

    fun installedApps(context: Context): List<Map<String, Any>> {
        val packageManager = context.packageManager
        val launcherIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolved = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.queryIntentActivities(launcherIntent, PackageManager.ResolveInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            packageManager.queryIntentActivities(launcherIntent, 0)
        }

        val seen = HashSet<String>()
        return resolved.mapNotNull { info ->
            val activityInfo = info.activityInfo ?: return@mapNotNull null
            val packageName = activityInfo.packageName ?: return@mapNotNull null
            // Lockout must never monitor itself.
            if (packageName == context.packageName || !seen.add(packageName)) return@mapNotNull null
            val applicationInfo = activityInfo.applicationInfo
            mapOf<String, Any>(
                "packageName" to packageName,
                "label" to packageManager.getApplicationLabel(applicationInfo).toString(),
                "isSystem" to (applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM != 0),
            )
        }.sortedBy { (it["label"] as String).lowercase() }
    }
}
