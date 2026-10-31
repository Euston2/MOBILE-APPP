# Lockout

A hard-limit social-media usage tracker for Android. Pick the apps that eat your
day, set one combined daily limit, and Lockout blocks them the moment the limit
is reached — then keeps them blocked until midnight. No accounts, no cloud, no
way to talk yourself out of it at 11 p.m.

<p>
  <img alt="CI" src="https://github.com/Euston2/MOBILE-APPP/actions/workflows/ci.yml/badge.svg" />
  <img alt="version" src="https://img.shields.io/badge/version-0.4.0-blue" />
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
| 5 | History & stats | `v0.5.0` | ⏳ next |
| 6 | Hardening (OEMs, edge cases, logging) | `v0.6.0` | ⏳ |
| 7 | Release (signed APK, GitHub Release) | `v1.0.0` | ⏳ |

Once the limit is reached, Lockout stamps a persisted lock and keeps the apps
blocked until local midnight. Limit and app changes made while a limit is active
are saved for the next day, so today's rules cannot be relaxed at 11 p.m.

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
- **Next-day changes** — while a limit is active, editing the limit or app
  selection saves a complete pending configuration for the next local midnight
  (`pending_limit_seconds`, `pending_effective_at`, and `pending_enabled` per
  app). Kotlin receives both the current and pending configurations and switches
  by clock, so the change lands at 00:00 even if Flutter is not running.
- **Reset** — `AlarmManager.setExactAndAllowWhileIdle` fires at 00:00 local time
  (with a doze-safe inexact fallback when exact-alarm access is unavailable); a
  `BOOT_COMPLETED`/`TIME_SET`/`TIMEZONE_CHANGED` receiver re-arms it. Any start
  of the app or service recovers a missed reset by comparing `now` with
  `next_reset_at`, clears the expired lock, folds the pending config into the
  active one, and archives yesterday's per-app totals for the history screen.

History is archived natively into a small JSON queue and imported into drift on
the next launch (drift is Dart-owned). The lock and its reset timestamp are
checked lazily, so a reboot, OEM task kill or a missed alarm cannot leave an
expired lock in place once Lockout runs again. A user force-stop disables
alarms/services until the app is opened, which Android does not allow an app to
override; the persisted state still recovers on that launch. If the device is
off for several days, only the most recent missing day is archived.

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
| Tests | `flutter_test`, Kotlin JUnit |
| CI/CD | GitHub Actions |

Storage split: settings and lock state (`daily_limit_seconds`,
`pending_limit_seconds`, `pending_effective_at`, `is_locked`, `locked_at`,
`next_reset_at`, onboarding flag) live in `shared_preferences` because the
service reads them on every check; the monitored-app list and all daily usage
history live in a drift/SQLite database so they can grow and be queried. See
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md#storage).

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
    ├── blocking/{data,domain,presentation}
    └── history/{data,domain,presentation}

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
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (user-granted) | Prevent OEM battery savers from killing the watcher. | 1/6 |
| `QUERY_ALL_PACKAGES` | List installed apps so you can choose which ones to monitor. | 1 |

Lockout never sends data off the device.

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
