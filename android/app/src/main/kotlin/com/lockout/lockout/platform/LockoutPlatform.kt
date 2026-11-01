package com.lockout.lockout.platform

import android.app.Activity
import android.content.Intent
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

            "openExactAlarmSettings" -> {
                PermissionController.openExactAlarmSettings(activity)
                result.success(null)
            }

            "openOemAutostartSettings" -> {
                PermissionController.openOemAutostartSettings(activity)
                result.success(null)
            }

            // Read-only health snapshot for the Protection check screen:
            // device/OEM, special-access states, exact-alarm availability,
            // enforcement config and the bounded event log.
            "getDiagnostics" -> runAsync(result) { Diagnostics.snapshot(activity) }

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
                val pendingPackages = call.argument<List<String>>("pendingPackages")?.toSet()
                    ?: emptySet()
                val pendingLimitSeconds = call.argument<Number>("pendingLimitSeconds")?.toInt()
                    ?: 0
                val pendingEffectiveAtMs = call.argument<Number>("pendingEffectiveAtMs")?.toLong()
                    ?: 0L
                val isLocked = call.argument<Boolean>("isLocked") == true
                val lockedAtMs = call.argument<Number>("lockedAtMs")?.toLong() ?: 0L
                val nextResetAtMs = call.argument<Number>("nextResetAtMs")?.toLong() ?: 0L
                if (
                    limitSeconds < 0 ||
                    pendingLimitSeconds < 0 ||
                    pendingEffectiveAtMs < 0 ||
                    lockedAtMs < 0 ||
                    nextResetAtMs < 0
                ) {
                    result.error(
                        "bad_args",
                        "limits and timestamps must be >= 0",
                        null,
                    )
                    return
                }

                try {
                    // The lock is native-authoritative: it is stamped while
                    // Flutter is not running, so a config push built from a
                    // stale Dart snapshot must not clear a lock that is still
                    // valid. An expired native lock is allowed to be replaced
                    // by the pushed (unlocked) state, which is how midnight is
                    // observed if Dart is open.
                    val previous = BlockingStore.load(activity)
                    val nowMs = System.currentTimeMillis()
                    val keepNativeLock = previous.isLocked &&
                        nowMs < previous.nextResetAtMs
                    val keepDartLock = isLocked && nowMs < nextResetAtMs
                    val locked = keepNativeLock || keepDartLock
                    val config = BlockingConfig(
                        monitoredPackages = packages,
                        dailyLimitSeconds = limitSeconds,
                        pendingPackages = pendingPackages,
                        pendingLimitSeconds = pendingLimitSeconds,
                        pendingEffectiveAtMs = pendingEffectiveAtMs,
                        isLocked = locked,
                        lockedAtMs = when {
                            keepNativeLock -> previous.lockedAtMs
                            locked -> lockedAtMs
                            else -> 0L
                        },
                        nextResetAtMs = when {
                            keepNativeLock -> previous.nextResetAtMs
                            else -> nextResetAtMs
                        },
                    )
                    BlockingStore.save(activity, config)
                    LockoutLog.info(
                        activity,
                        "config synced: ${config.monitoredPackages.size} apps, " +
                            "pending=${pendingEffectiveAtMs > 0L}",
                    )
                    if (keepNativeLock && !isLocked) {
                        // Correct Flutter's cache so the UI shows the lock on
                        // the next reload instead of believing its stale copy.
                        FlutterSettings.writeLock(
                            activity,
                            true,
                            config.lockedAtMs,
                            config.nextResetAtMs,
                        )
                    }
                    if (config.isActive) {
                        BlockingService.start(activity)
                    } else {
                        BlockingService.stop(activity)
                    }
                    result.success(null)
                } catch (error: Exception) {
                    LockoutLog.error(
                        activity,
                        "config sync failed: ${error.javaClass.simpleName}",
                    )
                    result.error(
                        "blocking_error",
                        error.message ?: error.javaClass.simpleName,
                        null,
                    )
                }
            }

            "stopBlocking" -> {
                BlockingService.stop(activity)
                LockoutLog.info(activity, "blocking stopped by user")
                result.success(null)
            }

            // Days archived by the native midnight reset and not yet imported
            // into drift. Dart calls this on launch and clears the queue after
            // writing the rows.
            "getPendingArchives" -> runAsync(result) {
                ArchiveStore.readAll(activity).map { archive ->
                    mapOf(
                        "date" to archive.date,
                        "totalSeconds" to archive.totalSeconds,
                        "limitSeconds" to archive.limitSeconds,
                        "limitHitAtMs" to archive.limitHitAtMs,
                        "apps" to archive.apps.map { (packageName, seconds) ->
                            mapOf("packageName" to packageName, "seconds" to seconds)
                        },
                    )
                }
            }

            "clearPendingArchives" -> {
                ArchiveStore.clearPending(activity)
                result.success(null)
            }

            // History CSV export. Sending plain text keeps the app free of a
            // FileProvider and storage permissions; the receiving app decides
            // whether to save it as a file.
            "shareText" -> {
                val subject = call.argument<String>("subject") ?: "Lockout history"
                val text = call.argument<String>("text")
                if (text.isNullOrBlank()) {
                    result.error("bad_args", "text is required", null)
                    return
                }
                try {
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_SUBJECT, subject)
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                    activity.startActivity(Intent.createChooser(send, subject))
                    result.success(null)
                } catch (error: Exception) {
                    result.error(
                        "share_error",
                        error.message ?: error.javaClass.simpleName,
                        null,
                    )
                }
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
