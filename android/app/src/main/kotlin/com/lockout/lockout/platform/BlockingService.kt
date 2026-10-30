package com.lockout.lockout.platform

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.lockout.lockout.MainActivity

/**
 * Foreground service that enforces the daily limit.
 *
 * Every two seconds it asks [ForegroundAppTracker] which app is in front. When
 * that app is monitored it sums today's usage across all monitored apps
 * ([BlockUsage]) and asks [BlockPolicy] whether to block. Blocking means showing
 * [BlockActivity]; if that activity cannot reach the foreground, [BlockOverlay]
 * covers the app instead. Both surfaces are native, so enforcement keeps working
 * when the Flutter engine has been killed.
 *
 * The configuration is never read from Flutter at runtime: Dart pushes it with
 * `setBlockingConfig` and [BlockingStore] caches it, so a service restart after
 * process death (START_STICKY) still knows what to enforce.
 */
class BlockingService : Service() {

    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var workerThread: HandlerThread
    private lateinit var worker: Handler
    private val tracker = ForegroundAppTracker()
    private var lastLaunchMs = 0L

    private val pollRunnable = object : Runnable {
        override fun run() {
            poll()
            worker.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        workerThread = HandlerThread("lockout-blocking").also { it.start() }
        worker = Handler(workerThread.looper)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val config = BlockingStore.load(this)
        if (!config.isActive) {
            stopSelf()
            return START_NOT_STICKY
        }

        try {
            startInForeground(config)
        } catch (_: Exception) {
            // Android 12+ can refuse a foreground start from the background.
            // Dart retries on the next config push; nothing to enforce here.
            stopSelf()
            return START_NOT_STICKY
        }

        worker.removeCallbacks(pollRunnable)
        worker.post(pollRunnable)
        return START_STICKY
    }

    override fun onDestroy() {
        worker.removeCallbacksAndMessages(null)
        workerThread.quitSafely()
        mainHandler.post { BlockOverlay.hide() }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /** Runs on the worker thread; never touches views directly. */
    private fun poll() {
        val config = BlockingStore.load(this)
        if (!config.isActive) {
            stopSelf()
            return
        }

        val nowMs = System.currentTimeMillis()
        val foreground = tracker.currentPackage(this, nowMs)
        if (foreground == null || foreground !in config.monitoredPackages) {
            mainHandler.post { BlockOverlay.hide() }
            return
        }

        val usedSeconds = BlockUsage.usedSecondsToday(this, nowMs, config.monitoredPackages)
        val reason = BlockPolicy.reasonForForeground(
            foregroundPackage = foreground,
            config = config,
            usedSecondsToday = usedSeconds,
            nowMs = nowMs,
        )
        if (reason == null) {
            mainHandler.post { BlockOverlay.hide() }
            return
        }

        mainHandler.post { presentBlock(reason, usedSeconds, config) }
    }

    /** Main thread: decide which block surface to show. */
    private fun presentBlock(
        reason: BlockReason,
        usedSeconds: Long,
        config: BlockingConfig,
    ) {
        if (BlockActivity.isVisible) {
            BlockOverlay.hide()
            return
        }
        // The overlay is already covering the app; tapping it opens the detail
        // activity. Do not relaunch underneath it on every poll.
        if (BlockOverlay.isShowing) return

        val now = SystemClock.elapsedRealtime()
        if (now - lastLaunchMs >= LAUNCH_COOLDOWN_MS) {
            lastLaunchMs = now
            launchBlockActivity()
        }

        // ROMs may silently drop a background activity start. If the activity
        // has not resumed shortly after the launch, fall back to the overlay.
        mainHandler.postDelayed({
            if (!BlockActivity.isVisible && !BlockOverlay.isShowing) {
                showFallbackOverlay(reason, usedSeconds, config)
            }
        }, OVERLAY_DELAY_MS)
    }

    private fun launchBlockActivity() {
        try {
            startActivity(
                Intent(this, BlockActivity::class.java)
                    .addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS,
                    ),
            )
        } catch (_: Exception) {
            // Overlay fallback handles it below.
        }
    }

    private fun showFallbackOverlay(
        reason: BlockReason,
        usedSeconds: Long,
        config: BlockingConfig,
    ) {
        if (!Settings.canDrawOverlays(this)) return
        BlockOverlay.show(
            this,
            BlockCopy.title(reason),
            BlockCopy.detail(reason, usedSeconds, config.dailyLimitSeconds.toLong()),
        )
    }

    private fun startInForeground(config: BlockingConfig) {
        val notification = buildNotification(config)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(config: BlockingConfig): Notification {
        val openApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val appCount = config.monitoredPackages.size
        val limit = BlockCopy.formatDuration(config.dailyLimitSeconds.toLong())

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Lockout is watching")
            .setContentText(
                "$appCount ${if (appCount == 1) "app" else "apps"} · $limit daily limit",
            )
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentIntent(openApp)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Limit monitoring",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps the daily limit enforced while Lockout is not open."
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        /** Must match `AppConstants.serviceNotificationChannelId` in Dart. */
        private const val CHANNEL_ID = "lockout_service"
        private const val NOTIFICATION_ID = 42

        /** Matches the "within ~2 seconds" blocking target. */
        private const val POLL_INTERVAL_MS = 2_000L

        /** Minimum gap between block-activity launch attempts. */
        private const val LAUNCH_COOLDOWN_MS = 5_000L

        /** Time allowed for the block activity to resume before the overlay. */
        private const val OVERLAY_DELAY_MS = 900L

        /**
         * Starts (or reconfigures) the service. Safe to call from the activity
         * while the app is in the foreground.
         */
        fun start(context: Context) {
            ContextCompat.startForegroundService(
                context,
                Intent(context, BlockingService::class.java),
            )
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, BlockingService::class.java))
        }
    }
}
