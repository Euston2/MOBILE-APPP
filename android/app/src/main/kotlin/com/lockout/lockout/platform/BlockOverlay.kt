package com.lockout.lockout.platform

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Full-screen overlay used as the fallback block surface.
 *
 * Starting an activity from the background is restricted on Android 10+, but
 * apps holding [android.Manifest.permission.SYSTEM_ALERT_WINDOW] are allowed to
 * draw over other apps. If the block activity could not come to the front within
 * a moment, the service calls this instead, so the blocked app is covered even
 * on ROMs that silently refuse background activity starts.
 *
 * Always call [show]/[hide] on the main thread. The overlay is intentionally
 * non-focusable (the app underneath keeps its own focus) but still consumes
 * touches, which is all a block screen needs to do.
 */
object BlockOverlay {

    private var overlay: View? = null
    private var windowManager: WindowManager? = null

    val isShowing: Boolean
        get() = overlay != null

    fun show(context: Context, title: String, detail: String) {
        if (overlay != null) return

        val app = context.applicationContext
        val manager = app.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
            ?: return

        val root = LinearLayout(app).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.rgb(18, 18, 18))
            setPadding(dp(app, 32), dp(app, 32), dp(app, 32), dp(app, 32))
        }

        root.addView(TextView(app).apply {
            text = "LOCKOUT"
            setTextColor(Color.rgb(0xB3, 0x26, 0x1E))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            letterSpacing = 0.2f
        })
        root.addView(TextView(app).apply {
            text = title
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 30f)
            setPadding(0, dp(app, 8), 0, dp(app, 12))
        })
        root.addView(TextView(app).apply {
            text = detail
            setTextColor(Color.rgb(0xC7, 0xC7, 0xC7))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setPadding(0, 0, 0, dp(app, 20))
        })
        root.addView(Button(app).apply {
            text = "Open details"
            setOnClickListener { openDetails(app) }
        })

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.OPAQUE,
        ).apply { gravity = Gravity.CENTER }

        try {
            manager.addView(root, params)
            overlay = root
            windowManager = manager
        } catch (_: Exception) {
            // Overlay permission revoked between the check and addView; the
            // block activity remains the primary surface.
        }
    }

    /** Removes the overlay; safe to call when nothing is shown. */
    fun hide() {
        val view = overlay ?: return
        try {
            windowManager?.removeView(view)
        } catch (_: Exception) {
            // Already detached (e.g. process teardown).
        }
        overlay = null
        windowManager = null
    }

    private fun openDetails(context: Context) {
        try {
            context.startActivity(
                Intent(context, BlockActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            )
        } catch (_: Exception) {
            // Nothing else to show; the overlay still blocks the app.
        }
    }

    private fun dp(context: Context, value: Int): Int =
        (value * context.resources.displayMetrics.density).toInt()
}
