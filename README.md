# Lockout

A hard-limit social-media usage tracker for Android. Pick the apps that eat your
day, set one combined daily limit, and Lockout blocks them the moment the limit
is reached — then keeps them blocked until midnight. No accounts, no cloud, no
way to talk yourself out of it at 11 p.m.

<p>
  <img alt="CI" src="https://github.com/Euston2/MOBILE-APPP/actions/workflows/ci.yml/badge.svg" />
  <img alt="version" src="https://img.shields.io/badge/version-1.4.0-blue" />
  <img alt="platform" src="https://img.shields.io/badge/platform-Android-3DDC84" />
  <img alt="license" src="https://img.shields.io/badge/license-MIT-green" />
</p>

## Status

| Stage | Scope | Version | State |
| ----- | ----- | ------- | ----- |
| 0 | Project, folder structure, CI, Git workflow | `v0.0.1` | ✅ done |
| 1 | Permissions & usage tracking | `v0.1.0` | ✅ done |
| 2 | Limit setting, drift storage, progress ring | `v0.2.0` | ✅ done |
| 3 | Blocking engine (foreground service + overlay) | `v0.3.0` | ✅ done |
| 4 | Lock & midnight reset | `v0.4.0` | ✅ done |
| 5 | History & stats | `v0.5.0` | ✅ done |
| 6 | Hardening (OEMs, edge cases, logging) | `v0.6.0` | ✅ done |
| 7 | Release (friends-and-family preview) | `v1.0.2` | ✅ preview |
| 8 | Focus locks (overnight + study) | `v1.1.0` | ✅ preview |
| 9 | Cumulative study timer, missed-goal automation, focus analytics | `v1.2.0` | ✅ preview |
| 10 | Dark neon redesign + remaining-time notifications | `v1.3.0` | ✅ preview |
| 11 | Finite offline Reader + reading analytics | `v1.4.0` | 🚧 preview |

The `1.4.0` APK is currently a friends-and-family preview built from `develop`.
It is debug-signed and not on Play Store; use it only for feedback. A tagged
public release waits until release signing secrets and the device matrix are
complete.

Once the limit is reached, Lockout stamps a persisted lock and keeps the apps
blocked until local midnight. Limit and app changes made while a limit is active
are saved for the next day, so today's rules cannot be relaxed at 11 p.m.

Two optional hard focus locks sit on top of that:

- **Overnight lock** blocks the selected apps every night from 12:00 AM to
  8:00 AM. While that window is running it cannot be switched off.
- **Study lock** starts a one-off session immediately and closes the selected
  apps for the chosen duration (25 minutes to 4 hours). It cannot be stopped
  early.
- **Study timer** accumulates focus time across sessions for the local day. Pick
  a preset (15 minutes to 2 hours) or a custom length, pause/resume, and watch
  the total build toward an optional daily goal (up to 10 hours).
- **Missed-goal automation** is opt-in: after a configurable cutoff (8:00 PM by
  default), the selected apps stay blocked until midnight if today's focus total
  is below the goal. Meeting the goal lifts the block early. While that block is
  active, the goal/cutoff and Limit & apps controls are locked, but starting a
  focus session still works — that is the way out.

- **Remaining-time warnings** arrive natively at 1 hour, 30 minutes, 15 minutes
  and 5 minutes left on the active daily limit, even when another app is in front
  and Flutter is closed. The 5-minute notification has an **Add 10 min** action
  that works from the notification shade; it is intentionally the only place the
  extension exists.

While either focus lock or the missed-goal block is active, Limit & apps is
read-only so the block cannot be bypassed by relaxing the limit or changing the
app selection.

## How it works (v1 target)

- **Tracking** — `UsageStatsManager` reports foreground time per package since
  local midnight. The combined total across the monitored apps is the number
  that counts against the limit.
- **Blocking** — a foreground service watches the foreground app every two
  seconds. When the limit is crossed (or you open a monitored app while locked)
  a full-screen native `BlockActivity` is launched above it. If a ROM silently
  refuses background activity starts, a full-screen overlay covers the app
  instead; both surfaces are native so blocking survives the Flutter process.
- **Lock** — once the limit is hit, the native service stamps `is_locked`,
  `locked_at` and `next_reset_at` in `shared_preferences` and in its own config
  cache. The block decision then trusts the persisted lock, not the live usage
  counter, so changing or removing the limit cannot unblock an app before
  midnight. The setting is read-only while locked.
- **Remaining-time warnings** — the watcher checks the live allowance every 30
  seconds and posts at 1 hour, 30 minutes, 15 minutes and 5 minutes left. Each
  tier is recorded in private native prefs per day and limit, so it fires once;
  active hard blocks cancel the warning instead. The 5-minute action adds 600
  seconds to the native config and writes the same limit into Flutter's prefs,
  so no Flutter engine is required.
- **Next-day changes** — while a limit is active, editing the limit or app
  selection saves a complete pending configuration for the next local midnight
  (`pending_limit_seconds`, `pending_effective_at`, and `pending_enabled` per
  app). Kotlin receives both the current and pending configurations and switches
  by clock, so the change lands at 00:00 even if Flutter is not running.
- **Focus locks** — the recurring overnight window (00:00–08:00) and a one-off
  study session share the same native enforcement as the daily limit. Study
  time has priority over the overnight window, then the daily lock, then the
  daily limit. Both are hard windows: the UI and controllers refuse to edit the
  limit or app selection until the active lock ends.
- **Focus timer and analytics** — focus seconds are banked per local day in
  `shared_preferences`; a running timer is also sent to Kotlin as start/end
  bounds so the native watcher can enforce the goal and archive the day without
  Flutter. The watcher stays alive while a timer was used today or a crossed
  midnight session is still running. At midnight Kotlin archives social usage,
  focus seconds and late-night usage (00:00–08:00) into the same JSON queue as
  the daily limit.
- **Reset** — `AlarmManager.setExactAndAllowWhileIdle` fires at 00:00 local time
  (with a doze-safe inexact fallback when exact-alarm access is unavailable); a
  `BOOT_COMPLETED`/`TIME_SET`/`TIMEZONE_CHANGED` receiver re-arms it. Any start
  of the app or service recovers a missed reset by comparing `now` with
  `next_reset_at`, clears the expired lock, folds the pending config into the
  active one, rolls a cross-midnight focus timer into the new day, and archives
  each finished day's per-app totals for the history screen (up to 14 missed
  days per recovery pass).
- **Protection check** — a dedicated screen shows the four essential accesses,
  exact-alarm access, the cached enforcement state and a bounded on-device event
  log. It includes manufacturer-specific autostart/battery steps for Xiaomi,
  Tecno/Infinix/itel, Samsung, Oppo/Realme, OnePlus, Huawei/Honor and Vivo/iQOO,
  with best-effort deep links and an app-details fallback. A copied report stays
  local until the user pastes it.
- **History** — archived days are imported into drift and shown in a 7-day or
  30-day chart with total/average/limit-hit stats, a grouped social-vs-focus
  chart, and expandable per-app breakdowns. The comparison chart puts social
  screen time, focus time and late-night (00:00–08:00) social usage side by side
  per day. Missing calendar days are padded with zeroes so the chart keeps a
  stable width, while averages count only days that were actually tracked. The
  CSV includes focus and late-night columns and hands the RFC 4180 snapshot to
  the system share sheet as plain text.
- **Reader** — a second bottom tab curates up to ten cached articles for the
  local day, with reading-time estimates and a "done for today" state. Sources
  (RSS, Hacker News, dev.to) and topics live in `assets/reader/sources.json` and
  Reader settings; WorkManager refreshes the cache roughly every six hours, and
  the tab never fetches on every open. Articles render natively after a one-time
  Readability extraction; "Open original" is a restricted WebView with no address
  bar, a per-article host allowlist, hard blocks for social hosts, and a
  confirmation before any external link. The block screen and overlay offer
  **Read something instead**, which opens the Reader without unlocking the
  guarded app. Bookmarks, per-day reading time and a scrolling-vs-reading card in
  History make the trade-off visible.

History is archived natively into a small JSON queue and imported into drift on
the next launch (drift is Dart-owned). The lock and its reset timestamp are
checked lazily, so a reboot, OEM task kill or a missed alarm cannot leave an
expired lock in place once Lockout runs again. A user force-stop disables
alarms/services until the app is opened, which Android does not allow an app to
override; the persisted state still recovers on that launch. After a long gap,
the newest 14 missing days are archived; older days and days before installation
are not reconstructed.

## Tech stack

| Concern | Choice |
| ------- | ------ |
| UI / logic | Flutter (stable 3.41.6) + Dart, Riverpod |
| Native layer | Kotlin, MethodChannel + EventChannel |
| Usage data | `UsageStatsManager` (`PACKAGE_USAGE_STATS`) |
| Blocking | Foreground service + full-screen Activity + overlay permission |
| Scheduling | `AlarmManager` exact alarm, `BOOT_COMPLETED` receiver |
| Storage | `drift` (SQLite) for history, `shared_preferences` for settings |
| Charts | `fl_chart` |
| Diagnostics | Bounded on-device event log (`LockoutLog`) + Logcat; no network |
| Tests | `flutter_test`, Kotlin JUnit |
| CI/CD | GitHub Actions |

Storage split: settings and lock state (`daily_limit_seconds`,
`pending_limit_seconds`, `pending_effective_at`, `is_locked`, `locked_at`,
`next_reset_at`, `overnight_lock_enabled`, `study_ends_at`,
`study_length_minutes`, onboarding flag) live in `shared_preferences` because
the service reads them on every check; the monitored-app list and all daily
usage history live in a drift/SQLite database so they can grow and be queried.
See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md#storage).

## Project structure

```
lib/
├── main.dart                  # entry point, ProviderScope
├── app.dart                   # MaterialApp, theme, routing
├── core/                      # cross-cutting: constants, theme, utils
│   ├── constants/
│   ├── theme/
│   └── utils/
├── domain/                    # entities, repository contracts, use cases
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/                      # drift database, preferences, repo implementations
│   ├── local/
│   ├── models/
│   └── repositories/
├── platform/                  # the ONLY place that talks to Kotlin
└── features/
    ├── onboarding/presentation
    ├── home/{data,domain,presentation}
    ├── limits/{data,domain,presentation}
    ├── focus/presentation
    ├── blocking/{data,domain,presentation}
    ├── history/{data,domain,presentation}
    └── protection/presentation

android/app/src/main/kotlin/com/lockout/lockout/
├── MainActivity.kt            # Flutter host activity
└── platform/                  # channels, services, receivers, alarm code

test/                          # Dart unit + widget tests
android/app/src/test/          # Kotlin unit tests
docs/                          # architecture, workflow, releasing
.github/                       # CI, release workflow, issue/PR templates
```

Layering rule: `presentation → domain ← data`. The presentation layer never
imports from `data`; `platform/` is wrapped by a repository implementation so
widgets stay testable.

## Getting started

Prerequisites: Flutter stable (`flutter doctor` clean), Android SDK 36,
JDK 17+ (Android Studio's bundled JBR works), a physical Android device
recommended (usage stats are unreliable on emulators).

```bash
flutter pub get
flutter run -d <device-id>          # debug build on device
```

Build artifacts:

```bash
flutter build apk --debug           # build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release         # signed only if android/key.properties exists
```

Quality gate (same as CI):

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
flutter build apk --debug
```

## Permissions

Every permission is user-visible and requested with an explanation screen.
Detailed rationale lives in [`docs/PERMISSIONS.md`](docs/PERMISSIONS.md); the
short version:

| Permission | Why Lockout needs it | Stage |
| ---------- | -------------------- | ----- |
| `PACKAGE_USAGE_STATS` (special access) | Read foreground time per app from `UsageStatsManager`. There is no other supported API for this. | 1 |
| `SYSTEM_ALERT_WINDOW` ("display over other apps") | Show the full-screen block over the blocked app. | 3 |
| `POST_NOTIFICATIONS` (Android 13+) | The blocking service must be a foreground service, which requires a visible notification. | 3 |
| `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_SPECIAL_USE` | Keep the watcher alive while another app is in the foreground. | 3 |
| `SCHEDULE_EXACT_ALARM` | Fire the midnight reset on time (falls back to a doze-safe inexact alarm when unavailable). | 4 |
| `RECEIVE_BOOT_COMPLETED` | Re-arm the reset and the service after a reboot. | 4 |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (user-granted) | Prevent OEM battery savers from killing the watcher. | 1, 6 |
| `QUERY_ALL_PACKAGES` | List installed apps so you can choose which ones to monitor. | 1 |

Lockout never sends data off the device. The Protection check screen can copy a
diagnostics report to the clipboard on request; only the event types, device
model and permission/config state are included.

## Branching & releases

`feature/<name>` → PR → `develop` → merge → `main` for a release. `main` is
always green and tagged. Conventional Commits are required, and every change
bumps the version in `pubspec.yaml` and adds a `CHANGELOG.md` entry.

See [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) for the exact commands and
[`docs/RELEASING.md`](docs/RELEASING.md) for signing secrets.

## Out of scope for v1

iOS, cloud sync, accounts, social features, per-app limits.

## License

MIT — see [LICENSE](LICENSE).
