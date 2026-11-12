package com.lockout.lockout.platform

import android.app.Activity
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.lockout.lockout.MainActivity
import java.util.concurrent.Executors

/**
 * Full-screen block screen shown above a blocked app.
 *
 * The activity computes its own state from [BlockingStore] instead of trusting
 * intent extras: whether the app should be blocked is a fact about the clock and
 * the usage counter, not about who launched the screen. It closes itself as soon
 * as [BlockPolicy] no longer reports a violation (for example after midnight, or
 * after the user changes the configuration from Lockout).
 *
 * While it is visible the service does not attempt another launch ([isVisible]),
 * which prevents a relaunch loop every poll.
 */
class BlockActivity : Activity() {

    private val mainHandler = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private var refreshing = false

    private lateinit var titleView: TextView
    private lateinit var detailView: TextView
    private lateinit var resetView: TextView
    private lateinit var metaView: TextView

    private val refreshRunnable = object : Runnable {
        override fun run() {
            refreshSnapshot()
            mainHandler.postDelayed(this, REFRESH_MS)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        buildUi()
    }

    override fun onResume() {
        super.onResume()
        isVisible = true
        BlockOverlay.hide()
        mainHandler.post(refreshRunnable)
    }

    override fun onPause() {
        isVisible = false
        mainHandler.removeCallbacks(refreshRunnable)
        super.onPause()
    }

    override fun onDestroy() {
        mainHandler.removeCallbacksAndMessages(null)
        worker.shutdownNow()
        super.onDestroy()
    }

    @Deprecated("Overriding the deprecated callback is the only way to intercept back on all supported versions")
    override fun onBackPressed() {
        goHome()
    }

    private fun buildUi() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setBackgroundColor(BACKGROUND)
            setPadding(dp(28), dp(56), dp(28), dp(28))
        }

        root.addView(TextView(this).apply {
            text = "LOCKOUT"
            setTextColor(MINT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            letterSpacing = 0.32f
            gravity = Gravity.CENTER
        })

        root.addView(TextView(this).apply {
            text = "ENFORCEMENT ACTIVE"
            setTextColor(CORAL)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 10f)
            letterSpacing = 0.12f
            gravity = Gravity.CENTER
            setPadding(dp(12), dp(6), dp(12), dp(6))
            background = rounded(
                fill = CORAL_DEEP,
                stroke = CORAL_TRANSLUCENT,
                radiusDp = 999,
            )
            val params = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            )
            params.topMargin = dp(22)
            layoutParams = params
        })

        root.addView(ImageView(this).apply {
            setImageResource(android.R.drawable.ic_lock_lock)
            imageTintList = ColorStateList.valueOf(CORAL)
            setPadding(dp(20), dp(20), dp(20), dp(20))
            background = rounded(CORAL_DEEP, CORAL_TRANSLUCENT, 999)
            val params = LinearLayout.LayoutParams(dp(84), dp(84))
            params.topMargin = dp(34)
            layoutParams = params
        })

        titleView = TextView(this).apply {
            setTextColor(TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 36f)
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, dp(20), 0, dp(10))
        }
        root.addView(titleView)

        detailView = TextView(this).apply {
            setTextColor(MUTED)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            gravity = Gravity.CENTER
            setLineSpacing(dp(3).toFloat(), 1f)
            setPadding(0, 0, 0, dp(22))
        }
        root.addView(detailView)

        val resetCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(18), dp(16), dp(18), dp(16))
            background = rounded(
                fill = SURFACE,
                stroke = OUTLINE,
                radiusDp = 22,
            )
        }
        resetCard.addView(TextView(this).apply {
            text = "RESET WINDOW"
            setTextColor(MUTED)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 10f)
            letterSpacing = 0.14f
        })
        resetView = TextView(this).apply {
            setTextColor(TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            setPadding(0, dp(5), 0, 0)
        }
        resetCard.addView(resetView)
        metaView = TextView(this).apply {
            setTextColor(MUTED)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setPadding(0, dp(6), 0, 0)
        }
        resetCard.addView(metaView)
        root.addView(
            resetCard,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ),
        )

        root.addView(TextView(this).apply {
            text = BlockCopy.FOOTER
            setTextColor(MUTED)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
            setLineSpacing(dp(2).toFloat(), 1f)
            setPadding(dp(4), dp(18), dp(4), dp(8))
        })

        root.addView(Button(this).apply {
            text = "Read something instead"
            isAllCaps = false
            setTextColor(MINT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            backgroundTintList = ColorStateList.valueOf(SURFACE_HIGH)
            setOnClickListener { openReader() }
        }, matchWidth())

        root.addView(TextView(this).apply {
            text = "A short, finite reading list. No feed, no autoplay."
            setTextColor(MUTED)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            gravity = Gravity.CENTER
            setPadding(dp(4), dp(6), dp(4), dp(18))
        })

        root.addView(Button(this).apply {
            text = "Close app"
            isAllCaps = false
            setTextColor(BACKGROUND)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            backgroundTintList = ColorStateList.valueOf(MINT)
            setOnClickListener { goHome() }
        }, matchWidth())

        root.addView(Button(this).apply {
            text = "Open Lockout"
            isAllCaps = false
            setTextColor(TEXT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            backgroundTintList = ColorStateList.valueOf(SURFACE_HIGH)
            setOnClickListener { openLockout() }
        }, matchWidth(topMarginDp = 8))

        setContentView(
            ScrollView(this).apply {
                isFillViewport = true
                addView(
                    root,
                    android.widget.FrameLayout.LayoutParams(
                        android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
                        android.widget.FrameLayout.LayoutParams.WRAP_CONTENT,
                    ),
                )
            },
        )
    }

    /** Recompute usage off the main thread; the query can touch many events. */
    private fun refreshSnapshot() {
        if (refreshing) return
        refreshing = true

        worker.execute {
            val config = BlockingStore.load(this)
            val nowMs = System.currentTimeMillis()
            val active = config.effectiveAt(nowMs)
            val usedSeconds = BlockUsage.usedSecondsToday(this, nowMs, active.packages)
            val reason = BlockPolicy.reasonFor(config, usedSeconds, nowMs)

            runOnUiThread {
                refreshing = false
                if (reason == null) {
                    finish()
                    return@runOnUiThread
                }
                titleView.text = BlockCopy.title(reason)
                detailView.text = BlockCopy.detail(
                    reason,
                    usedSeconds,
                    active.limitSeconds.toLong(),
                    config.studyEndsAtMs,
                    config.focusSecondsAt(nowMs).toLong(),
                    config.focusGoalSeconds.toLong(),
                )
                resetView.text = resetLabel(config, reason, nowMs)
                metaView.text = metaLabel(active, reason)
            }
        }
    }

    private fun resetLabel(
        config: BlockingConfig,
        reason: BlockReason,
        nowMs: Long,
    ): String {
        val endMs = when (reason) {
            BlockReason.STUDY -> config.studyEndsAtMs
            BlockReason.OVERNIGHT -> DayMath.overnightEndFor(nowMs)
            BlockReason.FOCUS_GOAL_MISSED -> DayMath.nextLocalMidnight(nowMs)
            BlockReason.LIMIT_REACHED,
            BlockReason.LOCKED,
            -> if (config.nextResetAtMs > nowMs) {
                config.nextResetAtMs
            } else {
                DayMath.nextLocalMidnight(nowMs)
            }
        }
        if (endMs <= nowMs) return "Resets at midnight"
        val remaining = BlockCopy.formatDuration((endMs - nowMs) / 1000)
        return "Resets in $remaining"
    }

    private fun metaLabel(
        active: ActiveLimit,
        reason: BlockReason,
    ): String {
        val apps = active.packages.size
        val noun = if (apps == 1) "app" else "apps"
        return when (reason) {
            BlockReason.OVERNIGHT -> "Overnight focus · 12:00 AM to 8:00 AM"
            BlockReason.STUDY -> "Study lock · $apps $noun paused"
            BlockReason.FOCUS_GOAL_MISSED -> "Focus goal missed · $apps $noun paused"
            BlockReason.LIMIT_REACHED,
            BlockReason.LOCKED,
            -> "$apps $noun · ${BlockCopy.formatDuration(active.limitSeconds.toLong())} daily limit"
        }
    }

    private fun goHome() {
        try {
            startActivity(
                Intent(Intent.ACTION_MAIN)
                    .addCategory(Intent.CATEGORY_HOME)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        } catch (_: Exception) {
            // Even without a launcher, finishing gets the user out of the app.
        }
        finishAndRemoveTask()
    }

    private fun openLockout() {
        startActivity(
            Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
        )
        finish()
    }

    /**
     * Opens Lockout on the Reader tab.
     *
     * This does not unlock the guarded app or stop enforcement: the blocked app
     * is still covered when the user comes back to it.
     */
    private fun openReader() {
        startActivity(
            Intent(this, MainActivity::class.java)
                .putExtra(EXTRA_OPEN_READER, true)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
        )
        finish()
    }

    private fun matchWidth(topMarginDp: Int = 0): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT,
        ).apply {
            topMargin = dp(topMarginDp)
        }

    private fun rounded(fill: Int, stroke: Int? = null, radiusDp: Int): GradientDrawable =
        GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            setColor(fill)
            cornerRadius = dp(radiusDp).toFloat()
            if (stroke != null) setStroke(dp(1), stroke)
        }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()

    companion object {
        private const val REFRESH_MS = 2_000L

        /**
         * Intent extra that opens Lockout on the Reader tab instead of Today.
         *
         * Also read by [LockoutPlatform] and set by [BlockOverlay].
         */
        const val EXTRA_OPEN_READER = "com.lockout.lockout.OPEN_READER"

        private val BACKGROUND = Color.rgb(0x06, 0x0A, 0x0C)
        private val SURFACE = Color.rgb(0x10, 0x16, 0x19)
        private val SURFACE_HIGH = Color.rgb(0x17, 0x20, 0x24)
        private val OUTLINE = Color.rgb(0x24, 0x33, 0x37)
        private val MINT = Color.rgb(0x63, 0xF4, 0xCE)
        private val CORAL = Color.rgb(0xFF, 0x96, 0x96)
        private val CORAL_DEEP = Color.rgb(0x3A, 0x1C, 0x1F)
        private val CORAL_TRANSLUCENT = Color.argb(0x55, 0xFF, 0x96, 0x96)
        private val TEXT = Color.rgb(0xF2, 0xF9, 0xF7)
        private val MUTED = Color.rgb(0x89, 0x98, 0x95)

        /** True between [onResume] and [onPause]; read by [BlockingService]. */
        @Volatile
        var isVisible: Boolean = false
            private set
    }
}
