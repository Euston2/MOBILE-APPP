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
| Lock logic | lock set once, cannot be cleared while `now < next_reset_at`, persists across cold start (`reconcileSettings`, `BlockPolicyTest`) |
| Focus locks | fixed 00:00–08:00 window, study active/expired, study-over-overnight priority, expired session cleanup, controller edit guards (`focus_window_test`, `focus_lock_test`, `reconcile_settings_test`, `settings_controller_test`) |
| Blocking decisions | unmonitored app, exact limit, over limit, active/expired lock, no limit, study/overnight focus (`BlockPolicyTest`) |
| Next-day settings | pending limit applied at its effective midnight, app add/remove planned and reconciled (`reconcile_settings_test`, `monitored_apps_planning_test`) |
| Reset logic | alarm fired at 00:00, missed alarm recovered on start, pending config materialised, double reset is idempotent (`DayMathTest`, manual matrix) |
| Archive | native queue imported once, drift upsert idempotent (`drift_monitored_apps_repository_test`, `archive_import_test`) |
| Archive catch-up | first run, gap, 14-day cap, month/year rollover, invalid/future marker (`ArchivePlannerTest`) |
| Diagnostics | native log sanitising/cap (`LockoutLogTest`), channel-map parsing and report formatting, Protection screen actions |
| History report | missing days padded, month/year rollover, exact-limit day, tracked-day average and limit counts (`history_report_test`) |
| History query | range is start-inclusive/end-exclusive, summaries join per-app rows, invalid dates skipped (`drift_history_repository_test`) |
| CSV export | header-only empty export, oldest-first rows, RFC 4180 quoting (`history_csv_test`) |
| History UI | navigation from Home, 7/30-day switch, app expansion, share success/failure, load-error retry (`history_screen_test`) |
| Focus UI | no-app guard, overnight toggle, study duration/start, running session locked controls, Home card and navigation (`focus_screen_test`, `home_screen_test`) |
| Protection UI | status/OEM copy, event list, autostart/battery/exact-alarm shortcuts, copied report (`protection_screen_test`, `oem_guidance_test`) |

Domain functions take the clock instant as a parameter (`reconcileSettings`,
`reconcileMonitoredApps`) so their tests are deterministic. Widget tests use
relative dates (`DateTime.now() + …`) and fake repositories.

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
| 7 | Wait for 00:00 (or set the device clock) | counter resets, lock clears, pending settings take over, yesterday archived |
| 8 | Change timezone forward past midnight | reset recognised once, not twice |
| 9 | Battery optimisation on vs off | service survives at least 10 min idle with optimisation off |
| 10 | OEM battery manager (Xiaomi/Tecno/Infinix/Samsung/Oppo/Huawei) | Protection check shows the right device guidance; shortcut opens the OEM/app-details screen; service survives after following the steps |
| 11 | Settings while locked | all edit controls disabled, "Locked until 00:00" visible; rejected by the controller too |
| 12 | Change limit/apps while a limit is active | "starts tomorrow" notice; today's ring and blocking unchanged; new values at 00:00 |
| 13 | Reboot while locked, open a monitored app | still blocked after boot; lock clears only at/after 00:00 |
| 14 | Turn the device off over several midnights, then boot | lock is recovered; each missing day is archived (up to 14) and imported into drift |
| 15 | Deny "Alarms & reminders" special access | Protection check shows fallback; midnight still recovers via the 2 s service poll / next start |
| 16 | History after several simulated days | 7/30-day chart, stats and CSV match the drift rows; empty history shows the midnight explanation; share sheet opens with the CSV text |
| 17 | Protection check status and report | permission rows match Settings; recent events appear after a service start; Copy diagnostics puts the report on the clipboard |
| 18 | Revoke a permission while Lockout is closed, then open Protection check | the affected essential check turns red and its button opens the right system screen |
| 19 | Enable Overnight lock, set the clock to 23:59 and open a selected app | app is blocked at 00:00; the switch stays on and cannot be turned off before 08:00 |
| 20 | Overnight lock active, open a selected app at 08:00 | block closes; apps open again and the switch becomes editable |
| 21 | Start each study preset and open a selected app | block appears within ~2 s; Limit & apps is read-only and there is no stop action |
| 22 | Let a study session expire with the app open | block screen closes; Home returns to the normal focus card; selection is editable again |
| 23 | Start a study session, then kill Lockout from Recents | native watcher keeps the app blocked until the study end time |
| 24 | Study session active, try to change the limit or app selection | both surfaces reject the edit and explain the active focus lock |

## Stage acceptance log

Accepted results are recorded at the end of each stage summary and in the
corresponding release notes.

