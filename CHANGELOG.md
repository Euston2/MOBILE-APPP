# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Release 1.3.0 preview

- Version `1.3.0+13`.
- Added native remaining-time warnings for the active daily social limit at
  **1 hour, 30 minutes, 15 minutes and 5 minutes** left. Checks run from the
  foreground watcher, so the warnings arrive while Flutter is closed and another
  app is in front.
- The 5-minute warning carries a native **Add 10 min** action. It extends the
  allowance and mirrors the new limit into Flutter's prefs without opening the
  app; the action is unavailable while the daily lock is already in force. The
  Flutter UI deliberately has no equivalent control.
- Warnings are deduplicated per local day and limit, do not fire while a hard
  block is active, and suppress stale tiers after a watcher restart. A limit that
  starts exactly on a threshold now gets that warning instead of missing it.
- Applied the dark neon **Lockout** design across Home, History, Limit & apps,
  Focus locks, Study timer, onboarding, Protection check and the native block
  screen/overlay: near-black surfaces, mint progress, coral locked states,
  rounded outlined cards, prominent tabular numbers and compact status pills.
- Home now opens with a daily-budget hero, remaining/limit metrics, a hard-lock
  commitment card and redesigned per-app rows; History groups totals, focus and
  late-night data on a matching dark surface.
- Added `UsageAlertPolicyTest` coverage for thresholds, dedupe masks, fresh-start
  handling and the native extension copy. Existing limits, focus locks, study
  timer, history, persistence and the pinned `sqlite3_flutter_libs: 0.5.42`
  remain unchanged.

### Release 1.2.0 preview

- Version `1.2.0+12`.
- Added a cumulative **Study timer** with 15m/25m/45m/1h/1h 30m/2h presets and
  a custom 5m–8h length. Sessions can be paused and resumed, and focus seconds
  bank into the current local day across sessions. The timer state is persisted
  in `shared_preferences` and mirrored to Kotlin, so a running session survives
  app restarts and the Flutter process being killed.
- Added an optional **daily focus goal** (0–600 minutes) with a configurable
  cutoff (default 8:00 PM). When automation is on and the cutoff passes while
  today's focus is below the goal, the selected apps stay blocked until
  midnight; meeting the goal lifts the block early. While the block is active,
  goal/automation/cutoff and Limit & apps edits are rejected, but starting a
  focus session remains available.
- Added focus and late-night analytics: the History screen now shows a grouped
  social-vs-focus chart per day, focus/late-night totals, per-day subtitles, and
  a late-night label on affected apps. Late-night means selected-app usage
  between local 12:00 AM and 8:00 AM.
- Native midnight archives now include `focusSeconds`, `lateNightSeconds` and
  per-app late-night usage. Drift schema is v3 with migrations; CSV export adds
  `focus_seconds`, `late_night_seconds` and `late_night_apps` columns.
- The native watcher stays alive while focus tracking is active for today, and
  `MidnightReset` rolls a cross-midnight focus timer into the new day so the
  previous day's archive and the new day's focus are both preserved.
- Added native focus-policy, focus-copy, day/minute and midnight-roll tests, plus
  Dart tests for timer math, goal/cutoff rules, controller guards, persistence,
  History comparison UI, drift fields and CSV output. Dart tests are now 195;
  all `:app` JVM tests, `flutter analyze` and the debug APK build pass.

### Release 1.1.0 preview

- Version `1.1.0+11`.
- Added **Focus locks**, both applying to the apps selected in Limit & apps:
  - **Overnight lock** — a recurring hard block every night from 12:00 AM to
    8:00 AM. Once enabled it cannot be turned off during the active window.
  - **Study lock** — a one-off session with `25m`, `45m`, `1h`, `1h 30m`, `2h`,
    `3h` or `4h` presets. It starts immediately, closes the selected apps, and
    cannot be stopped before its end time.
- Added a Focus locks screen with overnight and study controls, live session
  countdown/progress, and a shortcut back to the monitored-app selection. Home
  now shows a Focus locks card with the active lock and its end time.
- Limit & apps becomes read-only while either focus lock is active, and the
  Dart controllers reject edits as well, so a focused app cannot be unblocked by
  changing the limit or selection.
- Native enforcement understands both focus locks: study time has priority over
  the overnight window, which has priority over the daily lock and daily limit.
  The block screen, overlay and foreground notification use focus-specific copy
  and end times.
- Focus state is persisted in `shared_preferences` and pushed to the native
  watcher through `BlockingConfig`, so it survives app restarts and the Flutter
  process being killed.
- Added regression tests for focus-window boundaries, study expiry/cleanup,
  controller guards, prefs persistence, Focus and Home UI, native policy
  priority and native copy. Dart tests are now 163; all `:app` JVM tests,
  `flutter analyze` and the debug APK build pass.

### Release 1.0.2 preview

- Version `1.0.2+10`, with the app version shown in the Protection check support
  report footer.
- App names are the only visible labels in Limit & apps, Home and History.
  Package identifiers such as `com.twitter` are no longer shown as subtitles or
  fallback labels; unknown or removed apps use friendly placeholders.
- A saved daily limit now keeps applying on every later day without opening
  Limit & apps or saving again. Reset timestamps roll forward on both the Dart
  and native sides, the midnight alarm restarts the watcher if an OEM battery
  manager killed it during the night, and opening or refreshing Home re-pushes
  the saved config.
- Added regression tests for app-name-only labels and multi-day limit
  persistence.

### Release 1.0.1 preview

- Version `1.0.1+9`, with the app version shown in the Protection check support
  report footer.
- Friends-and-family preview APK built with release optimizations; it is
  debug-signed and is not a Play Store release.
- Fixed History and Limit & apps failing with a missing `libsqlite3.so`.
  `sqlite3_flutter_libs` is now pinned to the last functional 2.x release
  (`0.5.42`); `0.6.0+eol` is an empty migration stub.
- Replaced technical wording across onboarding, Home, History, limits and
  Protection check with plain-language copy.
- Raw platform and database errors are no longer shown in the app. They are
  logged with `debugPrint`, while screens show a simple retry message.
- Recent activity now uses friendly event names and `Update` / `Notice` /
  `Issue` labels; technical details remain in the copied support report.
- Release workflow now runs formatting, analysis, Flutter tests and the
  `:app` Kotlin tests before building, records the APK certificate, and fails
  if the APK is missing the bundled SQLite library.
- Release docs now cover preview builds, sideload verification, public signing
  setup and the deferred release checklist.
- Public tag, release signing and the device matrix remain pending until
  tester feedback is in.

## [0.6.0] - 2026-11-01

### Added

- Protection check screen, linked from Home and onboarding: four essential
  special accesses, exact-alarm precision, cached enforcement state, OEM
  autostart/battery guidance, recent events and a copyable diagnostics report.
- OEM guidance for Xiaomi/Redmi/POCO, Tecno/Infinix/itel, Samsung, Oppo/Realme,
  OnePlus, Huawei/Honor and Vivo/iQOO, with generic Android steps as fallback.
  Best-effort explicit-intent shortcuts open the manufacturer screen; a missing
  or blocked screen falls back to app details.
- Native diagnostics snapshot (`getDiagnostics`) and the
  `openOemAutostartSettings` / `openExactAlarmSettings` channel methods.
- Bounded on-device event log (`LockoutLog`): 50 entries, 240 characters each,
  newline sanitising, Logcat under the `Lockout` tag and a private prefs copy.
  Service start/stop, config sync, lock stamp/clear, alarm arming, reset/archive,
  boot/time changes and failures are recorded; no app contents or package names.
- Catch-up archiving for up to 14 missed days (`ArchivePlanner`), using the
  configuration that governed each day and attributing a carried-over lock to
  that day's start.
- Safe intent handling for settings screens: `SecurityException` and missing
  activities fall back instead of crashing, and exact-alarm scheduling has a
  final failure path.
- Kotlin tests for the catch-up planner, log sanitising and strict date parsing;
  Dart tests for OEM mapping, diagnostics parsing/reporting and the Protection
  screen. Dart tests are now 113; the 46 `:app` JVM tests, `flutter analyze` and
  the debug APK build also pass.

### Changed

- Home now has a Protection check card, and onboarding links to the
  device-specific battery help.
- Reset recovery archives every missing day in its bounded window instead of
  only the most recent one.
- Documentation now describes the diagnostics log, OEM shortcuts, exact-alarm
  status and the 14-day catch-up limit.

### Notes

- The event log stays on the device; the optional clipboard report is the only
  way it leaves, and it contains no app contents or package names.
- A user force-stop still disables alarms/services until Lockout is opened.
  Android does not allow an app to override that.
- Catch-up is capped at the newest 14 missing days; older history and days
  before installation are not reconstructed.
- Device Admin remains out of scope for v1.
- Device acceptance for OEM killing, reboots and the real midnight was not run
  in this environment: no Android device was attached.

## [0.5.0] - 2026-10-31

### Added

- History screen, opened from Home: a 7-day/30-day window with total time,
  tracked-day average and limit-hit count, plus `fl_chart` bars for each
  archived day, tooltips, and a dashed guide when the limit stayed unchanged.
- Per-day expansion showing the time spent in each app with friendly labels.
- CSV export: `historyCsv` builds an RFC 4180 snapshot with the date, daily
  totals, limit, hit time and per-app seconds. The system share sheet receives
  it as plain text through a new `shareText` MethodChannel (`ACTION_SEND`), so
  no storage permission or FileProvider is needed.
- `HistoryRepository.loadDays` and `DriftHistoryRepository.loadDays` join
  `daily_summary` with `daily_usage` over a local date range.
- `buildHistoryReport` pads missing calendar days with zeroes (stable chart
  width) and `summarizeHistory` averages only tracked days. Strict
  `localDateKey`/`parseLocalDateKey` helpers keep query keys aligned with the
  native archive format.
- Tests: report padding/statistics/month rollover, CSV quoting, drift range and
  join queries, and history navigation, range switching, app expansion, CSV
  sharing and error recovery. Dart tests are now 102; the 31 `:app` JVM tests,
  analyze and the debug APK build also pass.

### Changed

- Home's app bar now includes a History action.
- History reports only finished days; the screen states that today's usage
  lives on Home until the midnight reset.

### Notes

- CSV is shared as plain text, not as a file attachment.
- Only days archived by the native reset are shown. Days before Lockout was
  installed, or days skipped by a long force-stop/offline gap, are not
  reconstructed.
- Device acceptance for the share sheet and chart rendering was not run in this
  environment: no Android device was attached.

## [0.4.0] - 2026-10-31

### Added

- Persisted daily lock: when the combined monitored usage reaches the limit, the
  native service stamps `is_locked`, `locked_at` and `next_reset_at` in its own
  cache and in Flutter's `shared_preferences`; blocking no longer depends on the
  live usage counter, so lowering or removing the limit cannot unblock early.
- Lock read-only UI: Home shows "Locked until 00:00" with a countdown, and the
  limit/app editor is disabled. Controllers also reject edits while locked, in
  case a screen was built before the native lock landed.
- Midnight reset: exact `AlarmManager` alarm (with a doze-safe inexact fallback
  when `SCHEDULE_EXACT_ALARM` access is unavailable), `BOOT_COMPLETED`,
  `TIME_SET`, `TIMEZONE_CHANGED` and `MY_PACKAGE_REPLACED` recovery, plus a
  clock check on every service poll and app start. A missed alarm cannot leave
  an expired lock in place.
- Next-day settings: while a limit is active, limit and app-selection changes are
  scheduled for the next local midnight (`pending_limit_seconds`,
  `pending_effective_at`, `monitored_apps.pending_enabled`, drift schema v2 with
  migration). Kotlin receives the complete pending configuration and switches by
  clock at 00:00, even when Flutter is not running. The first configuration
  still applies immediately.
- Home and the editor explain scheduled changes ("New settings start at 00:00")
  and what still applies today.
- History archiving: at reset the native side writes yesterday's per-app totals
  to a small JSON queue; the app imports it into `daily_usage`/`daily_summary`
  on launch or refresh. Imports are idempotent (drift upserts).
- New tests: settings transitions, app planning/reconciliation, scheduled
  settings in the editor and Home, blocking-config payloads, prefs reload,
  drift upsert/archive, archive import, `DayMath` and pending `BlockPolicy`
  cases.

### Changed

- `BlockingConfig` now carries both the current and pending app sets/limits and
  the lock timestamp; the service resolves the effective configuration by clock.
- The service materialises a due pending configuration into the active one at
  reset, so notifications and the next day's archive use the correct values.
- Settings are re-read on resume and before every edit; a one-shot timer reloads
  them at the next lock/pending transition while the app stays open.

### Notes

- Only the most recent missing day is archived after a long offline gap; older
  days are not reconstructed.
- Android gives apps no way to survive a user force-stop. Persisted state
  recovers correctly the next time Lockout is opened.
- Device acceptance (block timing, midnight on a real clock, reboot, OEM battery
  managers) was not run in this environment: no Android device was attached.

## [0.3.0] - 2026-10-30

### Added

- `BlockingService`, a `specialUse` foreground service that polls the foreground
  app every 2 seconds while a limit and monitored apps are configured.
- Native `BlockPolicy` (pure Kotlin, JVM-tested) for the block decision: exact
  boundary, over-limit, active vs expired lock, unmonitored apps, no limit.
- Full-screen native `BlockActivity` showing used vs limit time, with "Close
  app" and "Open Lockout" actions; it closes itself if the violation clears.
- `BlockOverlay` fallback for ROMs that silently drop background activity
  starts, using the existing overlay permission; tapping it opens the details
  screen.
- `BlockingConfig` cached on the native side, so the watcher keeps enforcing
  after the Flutter process is killed; Dart pushes it whenever settings or the
  app selection change (`blockingSyncProvider`, watched by the app gate).
- Home banner when the native blocker cannot start, with a retry action.
- Kotlin tests for the blocking policy and the native duration formatting
  (22 JVM tests total).

### Changed

- Home states that monitored apps are blocked until 00:00 once the limit is
  reached.
- CI continues to run only `:app` JVM tests, now covering the blocking policy.

### Notes

- The lock is not yet stamped, so Stage 3 blocks because usage stays at or above
  the limit until midnight; the persisted lock and its midnight reset arrive
  with Stage 4. Until then, changing the limit can unblock early.

## [0.2.0] - 2026-10-29

### Added

- drift database (schema version 1) with `monitored_apps`, `daily_usage` and
  `daily_summary` tables; the generated schema is committed.
- `PrefsSettingsRepository` storing the daily limit, lock state, next reset and
  onboarding flag in `shared_preferences`.
- "Limit & apps" screen: 15-minute to 8-hour slider plus presets, searchable
  installed-app picker, an atomic save of both values, and a read-only mode when
  the lock is active.
- Home progress ring showing today's combined usage against the limit, with
  remaining time and an over-limit state; the per-app list is filtered to the
  monitored apps.
- `evaluateLimit` use case shared by Home (and later the block screen and lock
  checks).
- Onboarding completion is persisted, so a configured device boots straight to
  Home even when a permission is later revoked.
- Tests: limit boundary/rounding cases, settings prefs round-trip (including
  clearing `locked_at`), drift repository replacement, and widget tests for the
  ring, the limit editor and the persisted onboarding gate.

### Changed

- The app gate now reads the persisted settings before choosing onboarding or
  Home instead of keeping the flag in memory.

### Notes

- Lock enforcement, the midnight reset and the "changes take effect the next
  day" rule arrive with Stage 4. Until then a saved limit applies to today's
  counter immediately and the lock guard is dormant.

## [0.1.0] - 2026-10-29

### Added

- Permission onboarding with live status for usage access, overlay,
  notifications and battery-optimisation exemption, each deep-linking to its
  system screen and re-checked when the app resumes.
- Native usage tracking over `UsageStatsManager.queryEvents`: foreground
  resume/pause/lock events are clipped to local midnight by a pure
  `UsageAggregator`, so numbers match "since 00:00" rather than a drifting
  daily bucket.
- Installed-app catalogue (`PackageManager` + `QUERY_ALL_PACKAGES`) with
  labels and a system flag, excluding Lockout itself.
- Home screen with today's combined time, per-app breakdown with bars, manual
  pull-to-refresh and a five-second poll while visible.
- Single Kotlin `LockoutPlatform` MethodChannel (`getPermissionStatus`,
  settings intents, `getInstalledApps`, `getUsageSince`) with async work off
  the main thread.
- Dart domain layer: `UsageRepository`, `PermissionsRepository`,
  `summarizeUsage`, `startOfLocalDay`/`nextLocalMidnight`, duration formatting.
- Tests: 9 JVM tests for `UsageAggregator`, plus Dart unit tests for the time
  window, aggregation and formatting, and widget tests for onboarding and Home.
- Manifest permissions for usage access, package visibility, overlay,
  notifications and battery-optimisation exemption, each documented inline.

## [0.0.1] - 2026-10-29

### Added

- Flutter project (`lockout`) with Android-only target, Material 3 theme and a
  Riverpod `ProviderScope` at the root.
- Clean-architecture folder skeleton: `core`, `domain`, `data`, `platform` and
  `features/{onboarding,home,limits,blocking,history}`.
- Kotlin package layout (`com.lockout.lockout`) with a dedicated `platform`
  package for the future channels, services and receivers.
- GitHub Actions `ci.yml` (format, analyze, test, debug APK, gated Kotlin unit
  tests) and `release.yml` (signed APK on `v*` tags, debug-signed with a warning
  until the keystore secrets exist).
- Issue templates (bug, feature) and a pull-request template.
- `README.md`, `CHANGELOG.md`, `LICENSE`, architecture/permissions/workflow docs.
- Release signing plumbing in Gradle via git-ignored `android/key.properties`.
- Widget tests for app boot and small-screen layout.

[Unreleased]: https://github.com/Euston2/MOBILE-APPP/compare/v0.6.0...develop
[0.6.0]: https://github.com/Euston2/MOBILE-APPP/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/Euston2/MOBILE-APPP/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/Euston2/MOBILE-APPP/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/Euston2/MOBILE-APPP/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/Euston2/MOBILE-APPP/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Euston2/MOBILE-APPP/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/Euston2/MOBILE-APPP/releases/tag/v0.0.1
