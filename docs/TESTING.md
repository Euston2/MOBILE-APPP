# Testing

Two layers: automated checks that run in CI, and a device matrix that can only be
verified on real hardware (usage stats and background killing do not behave on
emulators).

## Automated

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
cd android && ./gradlew :app:testDebugUnitTest   # JVM tests in :app only
```

What must always be covered by unit tests:

| Area | Examples |
| ---- | -------- |
| Time windows | "today" from 00:00 local time, DST transitions, timezone changes mid-day, clock moved backwards |
| Limit logic | total == limit (blocked), total > limit, limit changed mid-day, no monitored apps |
| Lock logic | lock set once, cannot be cleared while `now < next_reset_at`, persists across cold start |
| Blocking decisions | unmonitored app, exact limit, over limit, active/expired lock, no limit (`BlockPolicyTest`) |
| Reset logic | alarm fired at 00:00, missed alarm recovered on start, double reset is idempotent |
| History | daily totals summed correctly held per app, week aggregation, CSV escaping |

Use an injected `Clock` (`package:clock` or a small interface) instead of
`DateTime.now()` in domain code so these are deterministic.

## Device matrix (manual)

Run before every release. Record device, Android version and OEM.

| # | Scenario | Expected |
| - | -------- | -------- |
| 1 | Fresh install, deny usage access | onboarding shows incomplete, tracking off, no crash |
| 2 | Grant usage access, compare today's total with Digital Wellbeing | within a small margin for each monitored app |
| 3 | Set a 1-minute limit, open a monitored app | block screen within ~2 s |
| 4 | Block screen: press Back, Home, Recents, rotate | block reappears / cannot reach the app |
| 5 | Limit hit, kill Lockout from Recents | service restarts, block still enforced |
| 6 | Limit hit, reboot device | still locked after boot, block persists |
| 7 | Wait for 00:00 (or use debug time simulation, Stage 4) | counter resets, lock clears, history row written |
| 8 | Change timezone forward past midnight | reset recognised once, not twice |
| 9 | Battery optimisation on vs off | service survives at least 10 min idle with optimisation off |
| 10 | OEM battery manager (Xiaomi/Tecno/Infinix/Samsung) | guidance screen shown, service survives after following it |
| 11 | Settings while locked | all edit controls disabled, "Locked until 00:00" visible |
| 12 | History after several simulated days | charts and CSV match database rows |

## Stage acceptance log

Accepted results are recorded at the end of each stage summary and in the
corresponding release notes.

