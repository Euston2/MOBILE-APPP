package com.lockout.lockout.platform

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/** One diagnostic event kept on the device for the Protection check screen. */
data class LogEntry(
    val timestampMs: Long,
    val level: String,
    val message: String,
)

/**
 * Bounded, on-device event log for support and troubleshooting.
 *
 * Only event types and counts are written: never app contents, package names or
 * usage totals. The same line also goes to Logcat under the `Lockout` tag. The
 * newest [MAX_ENTRIES] lines survive process death in a private prefs file and
 * can be copied from the Protection check screen; nothing is uploaded.
 *
 * Android owns the storage, so the class is deliberately small and the string
 * sanitising is the only piece unit tested on the JVM (`LockoutLogTest`).
 */
object LockoutLog {

    const val MAX_ENTRIES = 50
    const val MAX_MESSAGE_LENGTH = 240

    private const val TAG = "Lockout"
    private const val PREFS_NAME = "lockout_diagnostics"
    private const val KEY_EVENTS = "events"

    fun info(context: Context, message: String) = record(context, "INFO", message)

    fun warn(context: Context, message: String) = record(context, "WARN", message)

    fun error(context: Context, message: String) = record(context, "ERROR", message)

    fun read(context: Context): List<LogEntry> {
        val raw = prefs(context).getString(KEY_EVENTS, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.optJSONObject(index) ?: continue
                    val message = item.optString("message")
                    val level = item.optString("level")
                    if (message.isEmpty() || level.isEmpty()) continue
                    add(
                        LogEntry(
                            timestampMs = item.optLong("timestampMs", 0L),
                            level = level,
                            message = message,
                        ),
                    )
                }
            }
        }.getOrDefault(emptyList())
    }

    fun clear(context: Context) {
        prefs(context).edit().remove(KEY_EVENTS).apply()
    }

    /** One line, no newlines, bounded so a bad value cannot bloat prefs. */
    fun sanitize(message: String): String = message
        .replace(Regex("\\s+"), " ")
        .trim()
        .take(MAX_MESSAGE_LENGTH)

    @Synchronized
    private fun record(context: Context, level: String, message: String) {
        val safe = sanitize(message)
        if (safe.isEmpty()) return

        when (level) {
            "ERROR" -> Log.e(TAG, safe)
            "WARN" -> Log.w(TAG, safe)
            else -> Log.i(TAG, safe)
        }

        val entries = read(context) + LogEntry(
            timestampMs = System.currentTimeMillis(),
            level = level,
            message = safe,
        )
        write(context, entries.takeLast(MAX_ENTRIES))
    }

    private fun write(context: Context, entries: List<LogEntry>) {
        val array = JSONArray()
        for (entry in entries) {
            array.put(
                JSONObject()
                    .put("timestampMs", entry.timestampMs)
                    .put("level", entry.level)
                    .put("message", entry.message),
            )
        }
        prefs(context).edit().putString(KEY_EVENTS, array.toString()).apply()
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
