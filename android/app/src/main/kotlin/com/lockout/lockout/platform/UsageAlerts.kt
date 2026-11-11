package com.lockout.lockout.platform

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.lockout.lockout.MainActivity

/**
 * Remaining-time warnings for the daily social allowance.
 *
 * This is native on purpose: the warning must arrive while another app is in the
 * foreground and Flutter may not be running. The 5-minute warning is the only
 * one with an action, and that action edits the native config plus Flutter's
 * shared preferences instead of opening the app.
 */
object UsageAlerts {

    const val ACTION_ADD_TIME = "com.lockout.lockout.action.ADD_TIME"
    const val EXTRA_THRESHOLD = "threshold_seconds"

    private const val CHANNEL_ID = "lockout_usage_alerts"
    private const val ALERT_ID = 201
    private const val REQUEST_OPEN_APP = 201
    private const val REQUEST_ADD_TIME = 202

    private const val PREFS_NAME = "lockout_usage_alerts"
    private const val KEY_DAY = "day"
    private const val KEY_LIMIT = "limit"
    private const val KEY_LAST_REMAINING = "last_remaining"
    private const val KEY_LAST_CHECKED_AT = "last_checked_at"
    private const val KEY_MASK = "mask"

    /**
     * If the watcher was dead for longer than this, do not replay every warning
     * that was crossed in the gap. Treat it as a fresh start instead.
     */
    private const val STALE_GAP_MS = 90_000L

    /** Creates the alert channel; safe to call repeatedly. */
    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
            ?: return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Usage warnings",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description =
                "Warns you when your daily social-media allowance is nearly used up."
            setShowBadge(true)
        }
        manager.createNotificationChannel(channel)
    }

    /**
     * Called from the two-second watcher poll. Sends at most one warning per
     * threshold per day and limit, and never warns while an app is already
     * blocked.
     */
    fun check(
        context: Context,
        config: BlockingConfig,
        usedSeconds: Long,
        nowMs: Long,
    ) {
        val active = config.effectiveAt(nowMs)
        val blocked = !active.isActive ||
            BlockPolicy.reasonFor(config, usedSeconds, nowMs) != null
        if (blocked) {
            cancel(context)
            return
        }
        if (!canNotify(context)) return

        val remaining = UsageAlertPolicy.remainingSeconds(
            active.limitSeconds,
            usedSeconds,
        )
        if (remaining <= 0) {
            cancel(context)
            return
        }

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val day = DayMath.localDate(nowMs)
        val savedDay = prefs.getString(KEY_DAY, null)
        val savedLimit = prefs.getInt(KEY_LIMIT, 0)
        val savedRemaining = prefs.getInt(KEY_LAST_REMAINING, -1)
        val savedAt = prefs.getLong(KEY_LAST_CHECKED_AT, 0L)
        val savedMask = prefs.getInt(KEY_MASK, 0)

        val sameLimit = savedDay == day && savedLimit == active.limitSeconds
        val mask = if (sameLimit) savedMask else 0
        val fresh = !sameLimit || savedAt <= 0L ||
            nowMs - savedAt > STALE_GAP_MS

        var nextMask = mask
        var threshold: Int? = null

        if (fresh) {
            nextMask = UsageAlertPolicy.markPassed(mask, remaining)
            if (UsageAlertPolicy.shouldNotifyOnFreshStart(remaining)) {
                val tier = UsageAlertPolicy.tierFor(remaining)
                if (tier != null &&
                    !UsageAlertPolicy.hasNotified(mask, tier)
                ) {
                    threshold = tier
                }
            }
        } else if (remaining < savedRemaining) {
            val crossed = UsageAlertPolicy.crossedThreshold(
                savedRemaining,
                remaining,
            )
            if (crossed != null) {
                nextMask = UsageAlertPolicy.markPassed(mask, remaining)
                if (!UsageAlertPolicy.hasNotified(mask, crossed)) {
                    threshold = crossed
                }
            }
        }

        prefs.edit()
            .putString(KEY_DAY, day)
            .putInt(KEY_LIMIT, active.limitSeconds)
            .putInt(KEY_LAST_REMAINING, remaining)
            .putLong(KEY_LAST_CHECKED_AT, nowMs)
            .putInt(KEY_MASK, nextMask)
            .apply()

        if (threshold != null) {
            notify(
                context = context,
                threshold = threshold!!,
                remaining = remaining,
                appCount = active.packages.size,
            )
        }
    }

    /**
     * Adds ten minutes to the allowance currently in force.
     *
     * The config cache is native-authoritative, so it is updated first. The same
     * new value is written into Flutter's shared preferences, which means the
     * app reflects the extension when it is next opened. No Dart method is
     * required, and the app deliberately has no "+10" control of its own.
     */
    fun addTime(context: Context): Boolean {
        val config = BlockingStore.load(context)
        val nowMs = System.currentTimeMillis()
        val active = config.effectiveAt(nowMs)
        if (!active.isActive) return false
        if (config.isLocked && nowMs < config.nextResetAtMs) return false

        val newLimit = active.limitSeconds + UsageAlertPolicy.EXTENSION_SECONDS
        val pendingActive = config.pendingEffectiveAtMs > 0L &&
            nowMs >= config.pendingEffectiveAtMs &&
            config.pendingLimitSeconds > 0 &&
            config.pendingPackages.isNotEmpty()

        val updated = if (pendingActive) {
            config.copy(pendingLimitSeconds = newLimit)
        } else {
            config.copy(dailyLimitSeconds = newLimit)
        }
        BlockingStore.save(context, updated)

        FlutterSettings.writeLimits(
            context = context,
            dailyLimitSeconds = updated.dailyLimitSeconds,
            pendingLimitSeconds = updated.pendingLimitSeconds,
            pendingEffectiveAtMs = updated.pendingEffectiveAtMs,
        )

        // Reset the dedupe state so the new allowance starts cleanly. The next
        // warning is the 5-minute one (or 15 minutes if the user adds enough
        // time to pass that tier again).
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .clear()
            .apply()
        cancel(context)
        showConfirmation(context, newLimit)
        LockoutLog.info(
            context,
            "usage alert added 10 minutes; limit now $newLimit seconds",
        )
        return true
    }

    fun cancel(context: Context) {
        NotificationManagerCompat.from(context).cancel(ALERT_ID)
    }

    private fun notify(
        context: Context,
        threshold: Int,
        remaining: Int,
        appCount: Int,
    ) {
        ensureChannel(context)
        val openApp = PendingIntent.getActivity(
            context,
            REQUEST_OPEN_APP,
            Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = baseBuilder(
            context = context,
            title = UsageAlertPolicy.titleFor(threshold),
            body = UsageAlertPolicy.bodyFor(threshold, remaining, appCount),
            openApp = openApp,
        )

        if (threshold == UsageAlertPolicy.FIVE_MINUTES_SECONDS) {
            val addTime = PendingIntent.getBroadcast(
                context,
                REQUEST_ADD_TIME,
                Intent(context, UsageAlertActionReceiver::class.java)
                    .setAction(ACTION_ADD_TIME)
                    .putExtra(EXTRA_THRESHOLD, threshold),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            builder.addAction(
                android.R.drawable.ic_input_add,
                "Add 10 min",
                addTime,
            )
        }

        try {
            NotificationManagerCompat.from(context).notify(ALERT_ID, builder.build())
        } catch (_: SecurityException) {
            // The user revoked notifications between the check and the post.
        }
    }

    private fun showConfirmation(context: Context, newLimitSeconds: Int) {
        if (!canNotify(context)) return
        ensureChannel(context)
        val openApp = PendingIntent.getActivity(
            context,
            REQUEST_OPEN_APP,
            Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = baseBuilder(
            context = context,
            title = "10 minutes added",
            body = "Your daily allowance is now " +
                "${BlockCopy.formatDuration(newLimitSeconds.toLong())}.",
            openApp = openApp,
        )
        try {
            NotificationManagerCompat.from(context).notify(ALERT_ID, builder.build())
        } catch (_: SecurityException) {
            // Nothing to show; the extension itself is already persisted.
        }
    }

    private fun baseBuilder(
        context: Context,
        title: String,
        body: String,
        openApp: PendingIntent,
    ): NotificationCompat.Builder = NotificationCompat.Builder(
        context,
        CHANNEL_ID,
    )
        .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
        .setContentTitle(title)
        .setContentText(body)
        .setStyle(NotificationCompat.BigTextStyle().bigText(body))
        .setContentIntent(openApp)
        .setAutoCancel(true)
        .setOnlyAlertOnce(false)
        .setCategory(NotificationCompat.CATEGORY_REMINDER)
        .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

    private fun canNotify(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        return NotificationManagerCompat.from(context).areNotificationsEnabled()
    }
}

/** Handles only the 5-minute notification's "Add 10 min" action. */
class UsageAlertActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != UsageAlerts.ACTION_ADD_TIME) return
        UsageAlerts.addTime(context)
    }
}
