import 'package:lockout/domain/entities/monitored_app.dart';
import 'package:lockout/domain/entities/permission_snapshot.dart';
import 'package:lockout/domain/entities/usage_settings.dart';
import 'package:lockout/domain/repositories/monitored_apps_repository.dart';
import 'package:lockout/domain/repositories/settings_repository.dart';

/// In-memory settings store; [save] is observable so tests can assert that a
/// change was actually persisted.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({UsageSettings? initial})
    : settings =
          initial ??
          UsageSettings(
            dailyLimitSeconds: 0,
            isLocked: false,
            lockedAt: null,
            nextResetAt: DateTime.now().add(const Duration(hours: 8)),
            onboardingCompleted: false,
          );

  UsageSettings settings;
  int saveCalls = 0;

  @override
  Future<UsageSettings> load() async => settings;

  @override
  Future<void> save(UsageSettings settings) async {
    this.settings = settings;
    saveCalls++;
  }
}

/// In-memory monitored-apps store.
class FakeMonitoredAppsRepository implements MonitoredAppsRepository {
  FakeMonitoredAppsRepository([List<MonitoredApp> initial = const []])
    : apps = List.of(initial);

  List<MonitoredApp> apps;
  int replaceCalls = 0;

  @override
  Future<List<MonitoredApp>> getAll() async => List.unmodifiable(apps);

  @override
  Future<void> replaceAll(List<MonitoredApp> apps) async {
    this.apps = List.of(apps);
    replaceCalls++;
  }
}

/// Convenience settings for tests that only care about one field.
UsageSettings settingsWith({
  int dailyLimitSeconds = 0,
  bool isLocked = false,
  DateTime? lockedAt,
  bool onboardingCompleted = false,
}) => UsageSettings(
  dailyLimitSeconds: dailyLimitSeconds,
  isLocked: isLocked,
  lockedAt: lockedAt,
  nextResetAt: DateTime.now().add(const Duration(hours: 8)),
  onboardingCompleted: onboardingCompleted,
);

/// Snapshot with only usage access granted, useful for the onboarding flow.
const PermissionSnapshot usageOnly = PermissionSnapshot(
  usageAccess: true,
  overlay: false,
  notifications: false,
  batteryOptimizationIgnored: false,
);
