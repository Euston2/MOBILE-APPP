import 'package:lockout/domain/entities/blocking_config.dart';
import 'package:lockout/domain/entities/daily_archive.dart';
import 'package:lockout/domain/entities/monitored_app.dart';
import 'package:lockout/domain/entities/permission_snapshot.dart';
import 'package:lockout/domain/entities/usage_settings.dart';
import 'package:lockout/domain/repositories/blocking_repository.dart';
import 'package:lockout/domain/repositories/history_repository.dart';
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
  int reloadCalls = 0;

  @override
  Future<UsageSettings> load() async => settings;

  @override
  Future<void> save(UsageSettings settings) async {
    this.settings = settings;
    saveCalls++;
  }

  @override
  Future<void> reload() async {
    reloadCalls++;
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

/// In-memory stand-in for the native watcher.
class FakeBlockingRepository implements BlockingRepository {
  FakeBlockingRepository({this.error});

  final List<BlockingConfig> synced = [];
  int stopCalls = 0;
  Object? error;

  @override
  Future<void> sync(BlockingConfig config) async {
    if (error case final error?) throw error;
    synced.add(config);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

/// In-memory archive queue + drift sink for the history import.
class FakeHistoryRepository implements HistoryRepository {
  FakeHistoryRepository({List<DailyArchive> pending = const []})
    : pending = List.of(pending);

  List<DailyArchive> pending;
  final List<DailyArchive> saved = [];
  int clearCalls = 0;

  @override
  Future<List<DailyArchive>> readPendingArchives() async =>
      List.unmodifiable(pending);

  @override
  Future<void> saveArchive(DailyArchive archive) async {
    saved.add(archive);
  }

  @override
  Future<void> clearPendingArchives() async {
    pending = [];
    clearCalls++;
  }
}

/// Convenience settings for tests that only care about one field.
UsageSettings settingsWith({
  int dailyLimitSeconds = 0,
  bool isLocked = false,
  DateTime? lockedAt,
  bool onboardingCompleted = false,
  int? pendingLimitSeconds,
  DateTime? pendingEffectiveAt,
  DateTime? nextResetAt,
}) => UsageSettings(
  dailyLimitSeconds: dailyLimitSeconds,
  isLocked: isLocked,
  lockedAt: lockedAt,
  nextResetAt: nextResetAt ?? DateTime.now().add(const Duration(hours: 8)),
  onboardingCompleted: onboardingCompleted,
  pendingLimitSeconds: pendingLimitSeconds,
  pendingEffectiveAt: pendingEffectiveAt,
);

/// Snapshot with only usage access granted, useful for the onboarding flow.
const PermissionSnapshot usageOnly = PermissionSnapshot(
  usageAccess: true,
  overlay: false,
  notifications: false,
  batteryOptimizationIgnored: false,
);
