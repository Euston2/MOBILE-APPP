package com.lockout.lockout.platform

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** One finished day waiting to be imported into drift. */
data class UsageArchive(
    val date: String,
    val totalSeconds: Int,
    val limitSeconds: Int,
    val limitHitAtMs: Long,
    val apps: Map<String, Int>,
    val focusSeconds: Int = 0,
    val lateNightSeconds: Int = 0,
    val lateNightApps: Map<String, Int> = emptyMap(),
)

/**
 * Queue of days archived by the midnight reset.
 *
 * drift (SQLite) is owned by Flutter, so Kotlin cannot write history rows
 * directly. Instead it appends a compact JSON record here; Dart drains the queue
 * with `getPendingArchives` / `clearPendingArchives` on the next launch. Keeping
 * more than one record matters when the app is not opened for several days.
 */
object ArchiveStore {

    private const val PREFS_NAME = "lockout_archive"
    private const val KEY_PENDING = "pending_archives"
    private const val KEY_LAST_DATE = "last_archived_date"
    private const val MAX_RECORDS = 31

    fun readAll(context: Context): List<UsageArchive> {
        val raw = prefs(context).getString(KEY_PENDING, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.optJSONObject(index) ?: continue
                    val date = item.optString("date")
                    if (date.isEmpty()) continue
                    val apps = readAppMap(item.optJSONArray("apps"))
                    val lateNightApps = readAppMap(
                        item.optJSONArray("lateNightApps"),
                    )
                    add(
                        UsageArchive(
                            date = date,
                            totalSeconds = item.optInt("totalSeconds", 0),
                            limitSeconds = item.optInt("limitSeconds", 0),
                            limitHitAtMs = item.optLong("limitHitAtMs", 0L),
                            apps = apps,
                            focusSeconds = item.optInt("focusSeconds", 0),
                            lateNightSeconds = item.optInt(
                                "lateNightSeconds",
                                lateNightApps.values.sum(),
                            ),
                            lateNightApps = lateNightApps,
                        ),
                    )
                }
            }
        }.getOrDefault(emptyList())
    }

    fun append(context: Context, archive: UsageArchive) {
        val merged = readAll(context)
            .filterNot { it.date == archive.date }
            .plus(archive)
            .sortedBy { it.date }
            .takeLast(MAX_RECORDS)

        val array = JSONArray()
        for (day in merged) {
            val apps = writeAppMap(day.apps)
            val lateNightApps = writeAppMap(day.lateNightApps)
            array.put(
                JSONObject()
                    .put("date", day.date)
                    .put("totalSeconds", day.totalSeconds)
                    .put("limitSeconds", day.limitSeconds)
                    .put("limitHitAtMs", day.limitHitAtMs)
                    .put("apps", apps)
                    .put("focusSeconds", day.focusSeconds)
                    .put("lateNightSeconds", day.lateNightSeconds)
                    .put("lateNightApps", lateNightApps),
            )
        }
        prefs(context).edit().putString(KEY_PENDING, array.toString()).commit()
    }

    /** Reads the optional per-app seconds array used for both usage maps. */
    private fun readAppMap(rawApps: JSONArray?): Map<String, Int> {
        val apps = HashMap<String, Int>()
        if (rawApps == null) return apps
        for (appIndex in 0 until rawApps.length()) {
            val app = rawApps.optJSONObject(appIndex) ?: continue
            val packageName = app.optString("packageName")
            val seconds = app.optInt("seconds", 0)
            if (packageName.isNotEmpty() && seconds > 0) {
                apps[packageName] = seconds
            }
        }
        return apps
    }

    private fun writeAppMap(apps: Map<String, Int>): JSONArray {
        val array = JSONArray()
        for (entry in apps.entries.sortedBy { it.key }) {
            array.put(
                JSONObject()
                    .put("packageName", entry.key)
                    .put("seconds", entry.value),
            )
        }
        return array
    }

    fun clearPending(context: Context) {
        prefs(context).edit().remove(KEY_PENDING).commit()
    }

    fun lastArchivedDate(context: Context): String? =
        prefs(context).getString(KEY_LAST_DATE, null)

    fun markArchived(context: Context, date: String) {
        prefs(context).edit().putString(KEY_LAST_DATE, date).commit()
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
