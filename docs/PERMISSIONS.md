# Permissions

Lockout asks for invasive permissions by design: it must read app usage and draw
over other apps. Every request is preceded by a plain-language explanation and a
status row showing whether it is granted, so the user can always tell what is
active. Nothing leaves the device.

Statuses are checked with:
- Usage access: `AppOpsManager.OPSTR_GET_USAGE_STATS` (`unsafeCheckOpNoThrow`)
- Overlay: `Settings.canDrawOverlays(context)`
- Notifications: `NotificationManagerCompat.areNotificationsEnabled()` +
  `POST_NOTIFICATIONS` runtime permission on Android 13+ (API 33)
- Battery: `PowerManager.isIgnoringBatteryOptimizations(packageName)`
- Exact alarms: `AlarmManager.canScheduleExactAlarms()` on Android 12+ (displayed
  on the Protection check screen; not a hard requirement)

## Permission catalogue

### `android.permission.PACKAGE_USAGE_STATS` (special app access, not runtime)
**Why:** `UsageStatsManager.queryUsageStats` / `queryEvents` is the only
supported way to read per-app foreground time. Without it the app can count
nothing.
**How requested:** deep link to `Settings.ACTION_USAGE_ACCESS_SETTINGS`; the app
cannot grant it itself.
**Fallback if denied:** onboarding shows the step as incomplete and tracking
stays off; Home explains why the counter reads 0.

### `android.permission.SYSTEM_ALERT_WINDOW` (special app access)
**Why:** the block screen must appear above the blocked app. A plain activity
launch is banned from the background on Android 10+; a full-screen activity
launched from a foreground service needs either overlay permission or a
notification-based full-screen intent. Overlay permission is the deterministic
route.
**How requested:** `Settings.ACTION_MANAGE_OVERLAY_PERMISSION` with the package
URI.
**Fallback if denied:** the block falls back to a high-priority notification
and the Home screen warns that blocking is unreliable.

### `android.permission.POST_NOTIFICATIONS` (runtime, API 33+)
**Why:** a foreground service must post a persistent notification; on API 33+
the service stays alive but the notification is hidden without consent, which
looks like spyware. The block fallback and the 1h/30m/15m/5m remaining-time
warnings (including the native 5-minute **Add 10 min** action) also use it.
**How requested:** `ActivityResultContracts.RequestPermission` after the overlay
step.

### `android.permission.FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SPECIAL_USE`
**Why:** the watcher polls the foreground app while the user is inside another
app, so it must be a foreground service (API 34+ requires a typed permission and
a manifest `property` explaining the use).
**Note for Play Store:** `specialUse` requires a declaration; v1 is sideloaded /
GitHub-released so this is documented rather than submitted.

### `android.permission.SCHEDULE_EXACT_ALARM` (API 31/32) and
`android.permission.USE_EXACT_ALARM` (API 33+, alarm-clock use case)
**Why:** the midnight reset must fire on time. Inexact alarms can drift by
minutes to hours under Doze, which would leave the user locked past 00:00.
**How requested:** `Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM` on API 31/32;
on API 33+ `USE_EXACT_ALARM` is granted at install for alarm-clock semantics,
and the app still verifies `canScheduleExactAlarms()` and degrades gracefully.
**Fallback if denied:** `setAndAllowWhileIdle` (inexact) plus the
`next_reset_at` recovery check whenever the app or service starts.

### `android.permission.RECEIVE_BOOT_COMPLETED`
**Why:** after a reboot all alarms are cleared. Without this, a user who reboots
while locked would stay locked forever.
**Behaviour:** re-arms the midnight alarm and, if the limit was already hit,
restarts the blocking service.

### `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
**Why:** OEM battery managers (Xiaomi, Tecno, Infinix, Samsung) kill background
services aggressively. Exemption is the only sanctioned way to keep the watcher
alive.
**How requested:** `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` after
an explanation screen; the Protection check screen also links to it alongside
manufacturer-specific autostart instructions.

### `android.permission.QUERY_ALL_PACKAGES`
**Why:** the app picker must list launchable apps. Android 11+ package
visibility hides them otherwise. Alternative (`<queries>` intent filter for
`MAIN`/`LAUNCHER`) is narrower but still requires Play policy review, so the
broad permission is used and disclosed in the README.
**Data:** package names and labels are stored locally only.

### `android.permission.INTERNET` — **not** requested
There is no backend in v1. If a later version adds crash reporting, this
permission must be added with an explicit changelog note.

## Local diagnostics

`LockoutLog` keeps the newest 50 native event lines in a private prefs file and
mirrors them to Logcat under the `Lockout` tag. Lines contain event types and
counts (service start/stop, config sync, lock/reset/archive, alarm problems,
OEM shortcuts), never app contents or package names. The Protection check screen
shows the latest entries and can copy a report to the clipboard on request. There
is no network permission and nothing is uploaded automatically.

## Out of scope in v1

- `BIND_ACCESSIBILITY_SERVICE`: only if foreground polling proves unreliable
  (Stage 3 contingency). It is far more invasive and Play-restricted.
- Device Admin (`BIND_DEVICE_ADMIN`): considered for v0.6.0 but deliberately not
  added. It would make uninstalling harder while locked, at the cost of a much
  more invasive permission; v1 relies on the persisted lock instead.

## OEM guidance (implemented in v0.6.0)

Per-manufacturer paths for autostart / battery saving are shown in the in-app
Protection check screen: Xiaomi (Autostart + no battery restriction), Tecno/
Infinix/itel (Phone Master → Power saving → allow), Samsung (Background usage
limits → Never sleeping apps), Oppo/Realme (Auto-launch + background activity),
OnePlus (battery optimization + app launch), Huawei/Honor (App launch → manage
manually) and Vivo/iQOO (background power consumption). Where a known ROM
component exists, the screen offers an explicit-intent shortcut and falls back to
the app-details screen when the ROM hides or blocks it.
