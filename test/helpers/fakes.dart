import 'package:lockout/domain/entities/app_usage.dart';
import 'package:lockout/domain/entities/installed_app.dart';
import 'package:lockout/domain/entities/permission_snapshot.dart';
import 'package:lockout/domain/entities/usage_summary.dart';
import 'package:lockout/domain/repositories/permissions_repository.dart';
import 'package:lockout/domain/repositories/usage_repository.dart';

/// Permission fake whose snapshot can be changed between calls.
class FakePermissionsRepository implements PermissionsRepository {
  FakePermissionsRepository(this.snapshot);

  PermissionSnapshot snapshot;
  final List<PermissionKind> openedSettings = [];
  int statusCalls = 0;

  @override
  Future<PermissionSnapshot> getStatus() async {
    statusCalls++;
    return snapshot;
  }

  @override
  Future<void> openSettings(PermissionKind kind) async {
    openedSettings.add(kind);
  }
}

/// Usage fake returning a fixed summary and app list.
class FakeUsageRepository implements UsageRepository {
  FakeUsageRepository({
    this.summary,
    this.apps = const [
      InstalledApp(
        packageName: 'com.instagram.android',
        displayName: 'Instagram',
      ),
    ],
    this.error,
  });

  UsageSummary? summary;
  List<InstalledApp> apps;
  Object? error;
  int usageCalls = 0;

  @override
  Future<UsageSummary> getUsageForWindow({
    required DateTime start,
    required DateTime end,
    Set<String>? monitoredPackages,
  }) async {
    usageCalls++;
    if (error case final error?) throw error;
    return summary ??
        UsageSummary(
          windowStart: start,
          windowEnd: end,
          totalSeconds: 0,
          perApp: const [],
        );
  }

  @override
  Future<List<InstalledApp>> getInstalledApps() async => apps;
}

UsageSummary summaryOf(
  List<({String packageName, int seconds})> entries, {
  DateTime? windowStart,
}) {
  final start = windowStart ?? DateTime(2026, 10, 29);
  final perApp = entries
      .map((e) => AppUsage(packageName: e.packageName, seconds: e.seconds))
      .toList();
  return UsageSummary(
    windowStart: start,
    windowEnd: start.add(const Duration(hours: 12)),
    totalSeconds: perApp.fold(0, (sum, app) => sum + app.seconds),
    perApp: perApp,
  );
}

const PermissionSnapshot allGranted = PermissionSnapshot(
  usageAccess: true,
  overlay: true,
  notifications: true,
  batteryOptimizationIgnored: true,
);
