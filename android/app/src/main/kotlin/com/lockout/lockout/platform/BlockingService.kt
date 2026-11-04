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
        LockoutLog.info(
            this,
            if (intent == null) "service restarted by the system" else "service start requested",
        )
        val recovery = MidnightReset.recover(this)
        val config = recovery.config
        val nowMs = System.currentTimeMillis()
        if (!config.isActiveAt(nowMs)) {
            LockoutLog.info(this, "service stopped: no active configuration")
            MidnightAlarm.cancel(this)
            stopSelf()
            return START_NOT_STICKY
        }

        try {
            startInForeground(config)
        } catch (error: Exception) {
            // Android 12+ can refuse a foreground start from the background.
            // Dart retries on the next config push; nothing to enforce here.
            LockoutLog.error(
                this,
                "foreground service start failed: ${error.javaClass.simpleName}",
            )
            stopSelf()
            return START_NOT_STICKY
        }

        val active = config.effectiveAt(nowMs)
        val appCount = if (active.packages.isNotEmpty()) {
            active.packages.size
        } else {
            config.pendingPackages.size
        }
        LockoutLog.info(this, "service started: $appCount apps")
        MidnightAlarm.scheduleNext(this, nowMs)
        worker.removeCallbacks(pollRunnable)
        worker.post(pollRunnable)
        return START_STICKY
    }

    override fun onDestroy() {
        LockoutLog.info(this, "service destroyed")
        worker.removeCallbacksAndMessages(null)
        workerThread.quitSafely()
        mainHandler.post { BlockOverlay.hide() }
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // stopWithTask=false keeps enforcement alive after the recent-apps
        // swipe. Record it so a later support report can distinguish a task
        // removal from a system kill.
        LockoutLog.info(this, "task removed; service kept running")
        super.onTaskRemoved(rootIntent)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /** Runs on the worker thread; never touches views directly. */
    private fun poll() {
        var config = BlockingStore.load(this)
        val nowMs = System.currentTimeMillis()

        // Self-healing reset: archives yesterday and clears an expired lock even
        // when the midnight alarm never fired (force-stop, reboot, clock jump).
        val recovery = MidnightReset.recover(this, config, nowMs)
        config = recovery.config
        if (!config.isActiveAt(nowMs)) {
            MidnightAlarm.cancel(this)
            stopSelf()
            return
        }
        if (recovery.changed) {
            MidnightAlarm.scheduleNext(this, nowMs)
        }

        val active = config.effectiveAt(nowMs)
        val foreground = tracker.currentPackage(this, nowMs)
        if (foreground == null || foreground !in active.packages) {
            mainHandler.post { BlockOverlay.hide() }
            return
        }

        val usedSeconds = BlockUsage.usedSecondsToday(
            this,
            nowMs,
            active.packages,
        )

        // Crossing the limit turns into a persisted lock. From here on the
        // violation no longer depends on the current usage counter, so changing
        // the limit cannot unblock the app before midnight.
        if (BlockPolicy.shouldLock(config, usedSeconds, nowMs)) {
            config = LockState.lock(this, config, nowMs)
        }

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

        mainHandler.post {
            presentBlock(
                reason,
                usedSeconds,
                config.effectiveAt(nowMs).limitSeconds,
                config.studyEndsAtMs,
            )
        }
    }

    /** Main thread: decide which block surface to show. */
    private fun presentBlock(
        reason: BlockReason,
        usedSeconds: Long,
        limitSeconds: Int,
        studyEndsAtMs: Long,
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
                showFallbackOverlay(
                    reason,
                    usedSeconds,
                    limitSeconds,
                    studyEndsAtMs,
                )
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
        limitSeconds: Int,
        studyEndsAtMs: Long,
    ) {
        if (!Settings.canDrawOverlays(this)) return
        BlockOverlay.show(
            this,
            BlockCopy.title(reason),
            BlockCopy.detail(
                reason,
                usedSeconds,
                limitSeconds.toLong(),
                studyEndsAtMs,
            ),
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
        // Show the configuration in force now; before the first pending
        // midnight the active set is empty, so fall back to the scheduled one.
        val now = System.currentTimeMillis()
        val active = config.effectiveAt(now)
        val display = if (active.packages.isNotEmpty()) {
            active
        } else {
            ActiveLimit(config.pendingPackages, config.pendingLimitSeconds)
        }
        val appCount = display.packages.size
        val noun = if (appCount == 1) "app" else "apps"
        val text = when {
            config.studyEndsAtMs > now ->
                "$appCount $noun blocked for study time"
            config.overnightLockEnabled &&
                DayMath.isInOvernightWindow(now) ->
                "$appCount $noun blocked until 8:00 AM"
            active.isActive ->
                "$appCount $noun - " +
                    "${BlockCopy.formatDuration(active.limitSeconds.toLong())} " +
                    "daily limit"
            else -> "$appCount $noun selected"
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Lockout is watching")
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
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
            MidnightAlarm.cancel(context)
            context.stopService(Intent(context, BlockingService::class.java))
        }
    }
}
