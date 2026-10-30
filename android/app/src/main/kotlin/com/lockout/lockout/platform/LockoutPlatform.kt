package com.lockout.lockout.platform

import android.app.Activity
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * The single bridge between Flutter and Android.
 *
 * Everything the app needs from the OS goes through the one channel declared in
 * `AppConstants.platformChannelName`. Keeping it in one place means the Dart
 * side has exactly one seam to fake in tests.
 *
 * Usage queries run on a worker thread (they can touch thousands of events) and
 * results are posted back to the platform thread, as required by
 * [MethodChannel.Result].
 */
class LockoutPlatform(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL)
    private val worker: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    /** Called from `MainActivity.onDestroy` to avoid leaking the activity. */
    fun dispose() {
        channel.setMethodCallHandler(null)
        worker.shutdownNow()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPermissionStatus" -> result.success(PermissionController.snapshot(activity))

            // Each of these opens a system screen; the app cannot grant the
            // permission itself, so the UI re-checks status on resume.
            "openUsageAccessSettings" -> {
                PermissionController.openUsageAccessSettings(activity)
                result.success(null)
            }

            "openOverlaySettings" -> {
                PermissionController.openOverlaySettings(activity)
                result.success(null)
            }

            "openNotificationSettings" -> {
                PermissionController.openNotificationSettings(activity)
                result.success(null)
            }

            "openBatteryOptimizationSettings" -> {
                PermissionController.openBatteryOptimizationSettings(activity)
                result.success(null)
            }

            "openAppSettings" -> {
                PermissionController.openAppDetails(activity)
                result.success(null)
            }

            "getInstalledApps" -> runAsync(result) { AppCatalog.installedApps(activity) }

            "getUsageSince" -> {
                val startMs = call.argument<Number>("startMs")?.toLong()
                val endMs = call.argument<Number>("endMs")?.toLong()
                if (startMs == null || endMs == null || endMs <= startMs) {
                    result.error("bad_args", "startMs and endMs are required, endMs > startMs", null)
                    return
                }
                runAsync(result) { UsageStatsReader.read(activity, startMs, endMs) }
            }

            // Dart owns the policy; it pushes the resulting config here. The
            // service caches it so blocking survives the Flutter process.
            "setBlockingConfig" -> {
                val packages = call.argument<List<String>>("monitoredPackages")?.toSet()
                    ?: emptySet()
                val limitSeconds = call.argument<Number>("dailyLimitSeconds")?.toInt() ?: 0
                val isLocked = call.argument<Boolean>("isLocked") == true
                val nextResetAtMs = call.argument<Number>("nextResetAtMs")?.toLong() ?: 0L
                if (limitSeconds < 0 || nextResetAtMs < 0) {
                    result.error("bad_args", "limitSeconds and nextResetAtMs must be >= 0", null)
                    return
                }

                try {
                    val config = BlockingConfig(
                        monitoredPackages = packages,
                        dailyLimitSeconds = limitSeconds,
                        isLocked = isLocked,
                        nextResetAtMs = nextResetAtMs,
                    )
                    BlockingStore.save(activity, config)
                    if (config.isActive) {
                        BlockingService.start(activity)
                    } else {
                        BlockingService.stop(activity)
                    }
                    result.success(null)
                } catch (error: Exception) {
                    result.error(
                        "blocking_error",
                        error.message ?: error.javaClass.simpleName,
                        null,
                    )
                }
            }

            "stopBlocking" -> {
                BlockingService.stop(activity)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun runAsync(result: MethodChannel.Result, block: () -> Any?) {
        worker.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error("platform_error", error.message ?: error.javaClass.simpleName, null)
                }
            }
        }
    }

    companion object {
        /** Must match `AppConstants.platformChannelName` in Dart. */
        private const val CHANNEL = "com.lockout.lockout/platform"
    }
}
