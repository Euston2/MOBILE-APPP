import '../../domain/entities/app_usage.dart';
import '../../domain/entities/installed_app.dart';
import '../../domain/entities/usage_summary.dart';
import '../../domain/repositories/usage_repository.dart';
import '../../domain/usecases/summarize_usage.dart';
import '../../platform/lockout_platform.dart';

/// [UsageRepository] backed by `UsageStatsManager` through the platform channel.
class AndroidUsageRepository implements UsageRepository {
  const AndroidUsageRepository(this._platform);

  final LockoutPlatform _platform;

  @override
  Future<UsageSummary> getUsageForWindow({
    required DateTime start,
    required DateTime end,
    Set<String>? monitoredPackages,
  }) async {
    final raw = await _platform.getUsageSince(start: start, end: end);
    final apps = raw['apps'];
    final entries = <AppUsage>[];

    if (apps is List) {
      for (final item in apps) {
        if (item is! Map) continue;
        final packageName = item['packageName'];
        final millis = item['millis'];
        if (packageName is! String || packageName.isEmpty) continue;
        entries.add(
          AppUsage(
            packageName: packageName,
            seconds: millis is num ? millis.toInt() ~/ 1000 : 0,
          ),
        );
      }
    }

    return summarizeUsage(
      windowStart: start,
      windowEnd: end,
      entries: entries,
      monitoredPackages: monitoredPackages,
    );
  }

  @override
  Future<List<InstalledApp>> getInstalledApps() async {
    final raw = await _platform.getInstalledApps();
    final apps = <InstalledApp>[];
    for (final item in raw) {
      final packageName = item['packageName'];
      if (packageName is! String || packageName.isEmpty) continue;
      final label = item['label'];
      apps.add(
        InstalledApp(
          packageName: packageName,
          displayName: label is String && label.isNotEmpty
              ? label
              : packageName,
          isSystem: item['isSystem'] == true,
        ),
      );
    }
    return List.unmodifiable(apps);
  }
}
