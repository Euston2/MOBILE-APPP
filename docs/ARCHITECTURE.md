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

## Native layer

Planned Kotlin packages (same namespaces as the Dart side):

```
com.lockout.lockout/
├── MainActivity.kt          # Flutter host
└── platform/
    ├── LockoutChannels.kt   # MethodChannel/EventChannel registration
    ├── UsageStatsReader.kt  # UsageStatsManager queries + time-window math
    ├── AppBlockService.kt   # foreground service, polls foreground app
    ├── BlockActivity.kt     # full-screen block screen
    ├── MidnightAlarm.kt     # exact alarm scheduling/cancellation
    └── BootReceiver.kt      # BOOT_COMPLETED / TIME_SET / TIMEZONE_CHANGED
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
| Lock cannot be bypassed | domain + data | repository contract tests with fakes |
| Midnight reset, missed alarm | domain | clock-injected use case tests |
| Block screen scheduling | native | instrumentation/manual matrix in `docs/TESTING.md` |

Widget tests cover screens with fake repositories; no test depends on the real
device clock.
