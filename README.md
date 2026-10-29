# Lockout

A hard-limit social-media usage tracker for Android. Pick the apps that eat your
day, set one combined daily limit, and Lockout blocks them the moment the limit
is reached — then keeps them blocked until midnight. No accounts, no cloud, no
way to talk yourself out of it at 11 p.m.

<p>
  <img alt="CI" src="https://github.com/Euston2/MOBILE-APPP/actions/workflows/ci.yml/badge.svg" />
  <img alt="version" src="https://img.shields.io/badge/version-0.2.0-blue" />
  <img alt="platform" src="https://img.shields.io/badge/platform-Android-3DDC84" />
  <img alt="license" src="https://img.shields.io/badge/license-MIT-green" />
</p>

## Status

| Stage | Scope | Version | State |
| ----- | ----- | ------- | ----- |
| 0 | Project, folder structure, CI, Git workflow | `v0.0.1` | ✅ done |
| 1 | Permissions & usage tracking | `v0.1.0` | ✅ done |
| 2 | Limit setting, drift storage, progress ring | `v0.2.0` | ✅ done |
| 3 | Blocking engine (foreground service + overlay) | `v0.3.0` | ⏳ next |
| 4 | Lock & midnight reset | `v0.4.0` | ⏳ |
| 5 | History & stats | `v0.5.0` | ⏳ |
| 6 | Hardening (OEMs, edge cases, logging) | `v0.6.0` | ⏳ |
| 7 | Release (signed APK, GitHub Release) | `v1.0.0` | ⏳ |

## How it works (v1 target)

- **Tracking** — `UsageStatsManager` reports foreground time per package since
  local midnight. The combined total across the monitored apps is the number
  that counts against the limit.
- **Blocking** — a foreground service watches the foreground app every few
  seconds. When the limit is crossed (or you open a monitored app while locked)
  a full-screen `BlockActivity` is launched above it.
- **Lock** — once the limit is hit, `isLocked` is stamped with a timestamp and
  `next_reset_at` is written next to it in `shared_preferences`. Settings are
  read-only until then, including across reboots, because the service and the UI
  both trust the persisted timestamp rather than the alarm.
- **Reset** — `AlarmManager.setExactAndAllowWhileIdle` fires at 00:00 local time;
  a `BOOT_COMPLETED` receiver re-arms it; any start of the app or service
  recovers a missed reset by comparing `now` with `next_reset_at`.

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

Storage split: settings and lock state (`daily_limit_seconds`, `is_locked`,
`locked_at`, `next_reset_at`, onboarding flag) live in `shared_preferences`
because the service reads them on every check; the monitored-app list and all
daily usage history live in a drift/SQLite database so they can grow and be
queried. See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md#storage).

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
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Fire the midnight reset on time. | 4 |
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
