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
| Settings + lock (`daily_limit_seconds`, `is_locked`, `locked_at`, `next_reset_at`, onboarding flag) | `shared_preferences` via `PrefsSettingsRepository` | A handful of scalars that the blocking service reads on every check; prefs reads are cheap and survive process death. |
| Monitored apps (`monitored_apps`) | drift via `DriftMonitoredAppsRepository` | Edited and queried as a set, with display names kept for history labels. |
| Per-app daily totals (`daily_usage`) and per-day summary (`daily_summary`) | drift | Grows over time; feeds the history screen and charts in Stage 5. |

The schema lives in `lib/data/local/app_database.dart`. `app_database.g.dart` is
generated with `dart run build_runner build` and committed so CI does not need a
codegen step. Schema changes bump `schemaVersion` and add a migration.

Stage 2 note: a saved limit and app selection apply immediately while unlocked.
Enforcing the lock, the midnight reset and the "changes take effect the next
day" rule are Stage 4 behaviour; the editor already becomes read-only when
`is_locked` is true so the UI contract will not change.

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
    ├── AppBlockService.kt     # foreground service, polls foreground app (Stage 3)
    ├── BlockActivity.kt       # full-screen block screen (Stage 3)
    ├── MidnightAlarm.kt       # exact alarm scheduling/cancellation (Stage 4)
    └── BootReceiver.kt        # BOOT_COMPLETED / TIME_SET / TIMEZONE_CHANGED (Stage 4)
```

The Kotlin layer owns *facts* (which app is in front, how many seconds were
used, is the alarm armed). The Dart layer owns *policy* (is the limit hit, what
the block screen says, what a settings change does). This split keeps the risky
logic testable in Dart and the Android-specific code as thin as possible.

## Data flow (target v0.4)

1. `AppBlockService` polls the foreground package every 2 s while a monitored
   app is visible.
2. It asks `UsageStatsReader` for today's totals and sends a usage event to
   Flutter (Home updates live) or triggers `BlockActivity` when the limit is
   reached or the app is monitored while locked.
3. Crossing the limit writes `is_locked`, `locked_at`, `next_reset_at` and the
   per-app totals into `shared_preferences`/drift in the same transaction-like
   sequence, so a crash cannot lose the lock.
4. At 00:00 the alarm (or a recovery check on service/app start) writes
   `daily_summary` and `daily_usage`, clears the lock, arms the next alarm.

## Testing strategy

| Risk | Where | How |
| ---- | ----- | --- |
| "Used today" time window (midnight, DST, timezone change) | domain + Kotlin helper | `flutter_test` on a pure function; JUnit for the Kotlin mirror |
| Limit reached exactly at the boundary | domain | table-driven unit tests |
| Settings survive an app restart | data | `PrefsSettingsRepository` round-trip with mock `shared_preferences` |
| App selection is replaced atomically | data | drift in-memory database test |
| Lock cannot be bypassed | domain + data | repository contract tests with fakes |
| Midnight reset, missed alarm | domain | clock-injected use case tests |
| Block screen scheduling | native | instrumentation/manual matrix in `docs/TESTING.md` |

Widget tests cover screens with fake repositories; no test depends on the real
device clock.
