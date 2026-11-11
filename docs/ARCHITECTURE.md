# Architecture

Lockout is a single-module Flutter app with a thin Kotlin layer. This document
records the rules that keep it maintainable as stages are added.

## Layers

```
presentation  →  domain  ←  data
   (Flutter)     (pure Dart)   (drift, prefs, platform channels)
```

| Layer | Location | May import | Responsibility |
| ----- | -------- | ---------- | -------------- |
| Presentation | `lib/features/*/presentation`, `lib/app.dart` | domain, core | Widgets, Riverpod providers/notifiers, formatting |
| Domain | `lib/domain` | core | Entities, repository contracts, use cases (time-window math, lock rules, reset rules) |
| Data | `lib/data` | domain, core, platform | drift database, `shared_preferences`, repository implementations |
| Platform | `lib/platform` | — | The only code that knows channel names or method payloads |
| Core | `lib/core` | — | Constants, theme, pure helpers |

Non-negotiables:

1. `presentation` never imports `data` or `platform` directly; it depends on
   domain abstractions wired by Riverpod.
2. Business rules (when is the limit hit, what happens at 00:00, can settings be
   edited) live in `domain` as pure Dart so they can be unit-tested without a
   device.
3. Native Kotlin is small, documented, and reachable only through
   `lib/platform`. One channel file on each side, request/response via
   `MethodChannel`, streaming foreground changes via `EventChannel`.

## Storage

| Data | Where | Why |
| ---- | ----- | --- |
| Settings + lock (`daily_limit_seconds`, `pending_limit_seconds`, `pending_effective_at`, `is_locked`, `locked_at`, `next_reset_at`, `overnight_lock_enabled`, `study_ends_at`, `study_length_minutes`, focus goal/cutoff/automation, banked focus seconds, session bounds, onboarding flag) | `shared_preferences` via `PrefsSettingsRepository` | A handful of scalars that the blocking service reads on every check; prefs reads are cheap and survive process death. |
| Monitored apps (`monitored_apps`) | drift via `DriftMonitoredAppsRepository` | Edited and queried as a set, with display names kept for history labels; `pending_enabled` schedules a next-day change. |
| Per-app daily totals (`daily_usage`) and per-day summary (`daily_summary`) | drift | Grows over time; read by the history screen (`loadDays`) and padded/aggregated by the domain report. v3 adds per-app `late_night_seconds` and summary `focus_seconds` / `late_night_seconds`. |
| Days finished by the native reset | native JSON queue (`ArchiveStore`) | drift/SQLite is Dart-owned, so Kotlin appends a compact record; Dart drains it into drift on launch. |
| Diagnostic events | private native prefs (`LockoutLog`) | A bounded 50-line ring buffer for support; no app contents or package names, no network. |

The schema lives in `lib/data/local/app_database.dart`. `app_database.g.dart` is
generated with `dart run build_runner build` and committed so CI does not need a
codegen step. Schema changes bump `schemaVersion` and add a migration (v2 added
`monitored_apps.pending_enabled`; v3 added focus and late-night archive fields).

The lock has two readers: the service cannot wake Dart when it stamps a lock, so
`FlutterSettings.kt` writes `settings.is_locked` / `locked_at` /
`next_reset_at` into Flutter's prefs file, and `PrefsSettingsRepository.reload()`
refreshes the Dart cache on resume. Kotlin also keeps its own authoritative copy
in `BlockingStore` so enforcement does not depend on the Flutter engine.

## History

The History screen never invents days. It awaits the pending-archive import,
queries `[today - N, today)` as local calendar keys, and builds a report with
`buildHistoryReport`. That function pads missing days with zero usage so the
chart keeps a stable width, and `summarizeHistory` averages only days with an
archived total. Each row also carries the limit that applied that day, which is
why a changed limit does not draw a misleading chart guide.

That same report also carries focus seconds and late-night (00:00–08:00)
social usage. The comparison chart groups social time, focus time and late-night
usage per day, and a focus-only day still counts as data even though it is not
part of the screen-time average.

`historyCsv` lives in the domain and produces a CRLF, RFC 4180 snapshot. The
Android implementation sends it as plain text through `ACTION_SEND` via the
`shareText` channel method; plain text avoids a FileProvider and any storage
permission. The CSV excludes zero-usage padding rows but exports focus-only
days.

## Diagnostics

The Protection check screen is a read-only consumer of `Diagnostics.snapshot`:
device/OEM, the four essential permissions, exact-alarm access, power-save mode,
the cached enforcement config, the last archived date and the newest event
lines. `AndroidDiagnosticsRepository` parses that channel map into
`DeviceDiagnostics`; OEM copy lives in presentation, so the domain stays free of
wording.

`LockoutLog` writes one sanitised line per event to Logcat and to a private
prefs JSON array capped at 50 entries. It records state transitions and failures,
not every poll, so the two-second loop does not flood the buffer. The screen can
copy a plain-text report; nothing is uploaded and no network permission exists.

## Native layer

Planned Kotlin packages (same namespaces as the Dart side):

```
com.lockout.lockout/
├── MainActivity.kt            # Flutter host, owns the channel lifetime
└── platform/
    ├── LockoutPlatform.kt     # MethodChannel routing, background executor
    ├── PermissionController.kt# status checks + Settings intents
    ├── UsageStatsReader.kt    # UsageStatsManager -> events (Stage 1)
    ├── UsageAggregator.kt     # pure time-window math (JVM-tested)
    ├── AppCatalog.kt          # launchable apps for the picker
    ├── BlockingConfig.kt      # pure config snapshot + focus state (JVM-tested)
    ├── BlockPolicy.kt         # pure block decision + focus priority (JVM-tested)
    ├── BlockingStore.kt       # native cache of the config (own prefs file)
    ├── BlockingService.kt     # foreground service, polls the foreground app
    ├── ForegroundAppTracker.kt# event stream -> current foreground package
    ├── BlockUsage.kt          # combined monitored usage since local midnight
    ├── UsageAlertPolicy.kt    # threshold crossings + dedupe masks (JVM-tested)
    ├── UsageAlerts.kt         # native warnings + "Add 10 min" action
    ├── BlockActivity.kt       # full-screen block screen
    ├── BlockOverlay.kt        # overlay fallback when activity starts are dropped
    ├── BlockCopy.kt           # native strings + duration formatting (JVM-tested)
    ├── DayMath.kt             # local-day arithmetic (JVM-tested)
    ├── ArchivePlanner.kt      # bounded catch-up dates for missed midnights (JVM-tested)
    ├── LockoutLog.kt          # bounded on-device event log + Logcat
    ├── Diagnostics.kt         # read-only snapshot for Protection check
    ├── MidnightAlarm.kt       # exact alarm scheduling/cancellation
    ├── MidnightReceiver.kt    # alarm target: archive, clear lock, re-arm
    ├── MidnightReset.kt       # idempotent recovery/archive/materialise
    ├── LockState.kt           # stamp/clear the persisted lock
    ├── FlutterSettings.kt     # mirror lock fields into Flutter's prefs
    ├── ArchiveStore.kt        # native queue of finished days for drift
    └── BootReceiver.kt        # BOOT_COMPLETED / TIME_SET / TIMEZONE_CHANGED
```

`LockoutPlatform.kt` also handles `shareText`: it opens the system
`ACTION_SEND` chooser with the CSV as plain text, so the history export needs no
FileProvider or storage permission. `getDiagnostics` returns the Protection
check snapshot, while `openOemAutostartSettings` and
`openExactAlarmSettings` open the two protection system screens.

The Kotlin layer owns *facts* (which app is in front, how many seconds were
used, is the alarm armed). The Dart layer owns *policy* (is the limit hit, what
the block screen says, what a settings change does). This split keeps the risky
logic testable in Dart and the Android-specific code as thin as possible.

## Data flow

1. The Dart gate watches settings and the app selection, then pushes the
   resulting `BlockingConfig` to Kotlin (`setBlockingConfig`). Kotlin caches it
   in its own prefs file and starts or stops `BlockingService`. A scheduled
   change is sent as a complete second config (`pendingPackages`,
   `pendingLimitSeconds`, `pendingEffectiveAtMs`).
2. Every 2 s the service resolves the foreground package from `UsageEvents`,
   sums today's monitored usage, and asks the pure `BlockPolicy` for a verdict.
   The usage query only runs while a monitored app is actually in front, keeping
   the poll cheap. Every 30 s the same loop also passes the live allowance and
   cached config through `UsageAlertPolicy`: it posts at 1h/30m/15m/5m remaining,
   stores one dedupe mask per local day and limit in private prefs, and skips
   warnings while a hard block is active.
3. When usage reaches the effective limit, the service calls `LockState.lock`
   once: it writes `is_locked`, `locked_at`, `next_reset_at` to `BlockingStore`
   and to Flutter's prefs, then launches `BlockActivity`. If that activity does
   not reach the foreground (some ROMs drop background activity starts),
   `BlockOverlay` covers the app instead. Both read the same cached config and
   policy, so they cannot disagree with Home.
   The same config carries the focus flags (`overnightLockEnabled`,
   `studyEndsAtMs`) and the focus-timer snapshot (goal seconds, cutoff,
   automation, banked seconds, day start, session start/end). `BlockPolicy`
   checks study time first, then the fixed overnight window, then the
   missed-goal block, then the persisted daily lock, then the daily limit.
   Focus state is owned by `SettingsController`; `SetLimitsScreen` and
   `MonitoredAppsController` reject edits while a lock or missed-goal block is
   running so the selection cannot be relaxed out from under an active block.
   The 5-minute warning's `Add 10 min` action is a native `PendingIntent` to
   `UsageAlertActionReceiver`; it extends the active config, mirrors the new
   limit into Flutter's prefs and shows a confirmation without opening the app.
4. The block surfaces re-evaluate every 2 s and close themselves when the
   verdict clears. `BlockPolicy` trusts the persisted lock until
   `now >= next_reset_at`, so changing the limit cannot unblock early.
5. At midnight (or on the next service/app start if the alarm was missed),
   `MidnightReset.recover` archives every finished day still missing from
   `ArchiveStore` (capped at 14), including focus and late-night metrics, rolls
   a cross-midnight focus timer into the new day, materialises the pending
   config into the active one, clears the expired lock, writes the new
   `next_reset_at` back to Flutter's prefs and re-arms the alarm. The app gate
   drains `ArchiveStore` into drift on launch and Home's refresh imports any day
   archived while the app stayed open.
6. Dart and Kotlin both compare the clock with `next_reset_at`; the alarm only
   makes the transition prompt, it is never required for correctness.
7. The History screen awaits `archiveImportProvider`, reads the selected window
   from drift, and renders the padded report. Its CSV action generates the text
   in Dart and calls `shareText`, which opens the Android chooser; the share
   sheet is the only part that depends on the device.
8. Protection check loads `getDiagnostics` on open and resume. Permission and
   OEM buttons open system screens; the native layer falls back to app details
   when a ROM hides an intent. The event log is read-only and bounded.

## Testing strategy

| Risk | Where | How |
| ---- | ----- | --- |
| "Used today" time window (midnight, DST, timezone change) | domain + Kotlin helper | `flutter_test` on a pure function; JUnit for `DayMath` |
| Limit reached exactly at the boundary | domain + native | Dart table-driven tests and Kotlin `BlockPolicyTest` |
| Settings survive an app restart | data | `PrefsSettingsRepository` round-trip with mock `shared_preferences` |
| Native lock reaches the UI | data | prefs round-trip + `reload()`; native `FlutterSettings` keeps the same file/prefix (documented in code) |
| App selection is replaced atomically | data | drift in-memory database test |
| Next-day changes | domain | `planMonitoredApps` / `reconcileMonitoredApps`, `reconcileSettings` |
| Lock cannot be bypassed | domain + native | `reconcileSettings` tests and `BlockPolicyTest` (active/expired lock) |
| Block surfaces cannot disagree | native | shared `BlockPolicy`/`BlockCopy` used by service, activity and overlay |
| Missed midnight / reboot | native | `DayMath` tests plus manual reboot/time-change matrix |
| Catch-up archive stays bounded | native | `ArchivePlannerTest`: first run, current date, gap, 14-day cap, month/year boundary, invalid/future marker |
| Diagnostic log is safe | native | `LockoutLogTest`: newline flattening, trimming, 240-char cap |
| Diagnostics channel shape | data | `AndroidDiagnosticsRepository.parse` tests: defaults, events, malformed entries |
| OEM guidance mapping | presentation | `oem_guidance_test`: Xiaomi, Transsion, Samsung, Oppo, Huawei, OnePlus, generic fallback |
| Protection screen actions | presentation | widget test: status, OEM copy, event log, autostart/battery/exact-alarm shortcuts, copied report |
| Archive import is idempotent | data | drift `saveDailyArchive` upsert test + fake history import test |
| History window is stable | domain | `buildHistoryReport` tests: padding, rollover, exact limit, tracked-only average |
| History query joins the right rows | data | in-memory drift range/join test, including invalid dates |
| CSV stays valid | domain | `historyCsv` tests for ordering and RFC 4180 quoting |
| History screen recovers | presentation | widget tests with fake repository/exporter: empty, range switch, share failure, retry |
| Focus totals cross sessions and midnight | domain + native | `study_timer_test`, `reconcile_settings_test`, `MidnightResetTest` and `BlockingConfig.focusSecondsAt` tests |
| Goal block lifts exactly at cutoff/goal | domain + native | `study_timer_test`, `focus_lock_test`, `BlockPolicyTest` and controller guard tests |
| Warnings fire once at 1h/30m/15m/5m | native | `UsageAlertPolicyTest`: tier mapping, downward crossings, dedupe masks, fresh-start and exact-threshold handling |
| Focus/late-night archives survive the schema change | data | drift in-memory v3 round-trip, native-channel parsing and CSV tests |
| Comparison chart matches archived metrics | presentation | History widget test asserts the focus chart, totals and late-night labels |

Widget tests cover screens with fake repositories; no test depends on the real
device clock.
