package com.lockout.lockout.platform

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
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
            gravity = Gravity.CENTER
            setBackgroundColor(Color.rgb(18, 18, 18))
            setPadding(dp(32), dp(32), dp(32), dp(32))
        }

        root.addView(TextView(this).apply {
            text = "LOCKOUT"
            setTextColor(Color.rgb(0xB3, 0x26, 0x1E))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            letterSpacing = 0.2f
        })

        titleView = TextView(this).apply {
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 30f)
            setPadding(0, dp(8), 0, dp(12))
        }
        root.addView(titleView)

        detailView = TextView(this).apply {
            setTextColor(Color.rgb(0xC7, 0xC7, 0xC7))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setPadding(0, 0, 0, dp(8))
        }
        root.addView(detailView)

        root.addView(TextView(this).apply {
            text = BlockCopy.FOOTER
            setTextColor(Color.rgb(0x9E, 0x9E, 0x9E))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setPadding(0, 0, 0, dp(24))
        })

        root.addView(Button(this).apply {
            text = "Close app"
            setTextColor(Color.WHITE)
            backgroundTintList = android.content.res.ColorStateList.valueOf(
                Color.rgb(0xB3, 0x26, 0x1E),
            )
            setOnClickListener { goHome() }
        })

        root.addView(Button(this).apply {
            text = "Open Lockout"
            setTextColor(Color.rgb(0xE8, 0xE8, 0xE8))
            setOnClickListener { openLockout() }
        })

        setContentView(root)
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
                )
            }
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

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()

    companion object {
        private const val REFRESH_MS = 2_000L

        /** True between [onResume] and [onPause]; read by [BlockingService]. */
        @Volatile
        var isVisible: Boolean = false
            private set
    }
}
