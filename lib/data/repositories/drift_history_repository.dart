import 'package:drift/drift.dart';

import '../../core/utils/day_window.dart';
import '../../domain/entities/daily_archive.dart';
import '../../domain/entities/history_day.dart';
import '../../domain/repositories/history_repository.dart';
import '../../platform/lockout_platform.dart';
import '../local/app_database.dart';

/// [HistoryRepository] that drains the native midnight archive into drift.
class DriftHistoryRepository implements HistoryRepository {
  const DriftHistoryRepository(this._platform, this._database);

  final LockoutPlatform _platform;
  final AppDatabase _database;

  @override
  Future<List<DailyArchive>> readPendingArchives() async {
    final raw = await _platform.getPendingArchives();
    final archives = <DailyArchive>[];

    for (final item in raw) {
      final date = item['date'];
      final total = item['totalSeconds'];
      if (date is! String || date.isEmpty || total is! num) continue;

      final apps = <String, int>{};
      final rawApps = item['apps'];
      if (rawApps is List) {
        for (final entry in rawApps) {
          if (entry is! Map) continue;
          final packageName = entry['packageName'];
          final seconds = entry['seconds'];
          if (packageName is! String || packageName.isEmpty) continue;
          if (seconds is! num || seconds <= 0) continue;
          apps[packageName] = seconds.toInt();
        }
      }

      final lateNightApps = <String, int>{};
      final rawLateNightApps = item['lateNightApps'];
      if (rawLateNightApps is List) {
        for (final entry in rawLateNightApps) {
          if (entry is! Map) continue;
          final packageName = entry['packageName'];
          final seconds = entry['seconds'];
          if (packageName is! String || packageName.isEmpty) continue;
          if (seconds is! num || seconds <= 0) continue;
          lateNightApps[packageName] = seconds.toInt();
        }
      }

      final limit = item['limitSeconds'];
      final hitAtMs = item['limitHitAtMs'];
      final focusSeconds = item['focusSeconds'];
      final lateNightSeconds = item['lateNightSeconds'];
      archives.add(
        DailyArchive(
          date: date,
          totalSeconds: total.toInt(),
          limitSeconds: limit is num ? limit.toInt() : 0,
          limitHitAt: hitAtMs is num && hitAtMs > 0
              ? DateTime.fromMillisecondsSinceEpoch(hitAtMs.toInt())
              : null,
          apps: Map.unmodifiable(apps),
          focusSeconds: focusSeconds is num ? focusSeconds.toInt() : 0,
          lateNightSeconds: lateNightSeconds is num
              ? lateNightSeconds.toInt()
              : lateNightApps.values.fold(0, (sum, value) => sum + value),
          lateNightApps: Map.unmodifiable(lateNightApps),
        ),
      );
    }

    return List.unmodifiable(archives);
  }

  @override
  Future<void> saveArchive(DailyArchive archive) {
    return _database.saveDailyArchive(
      date: archive.date,
      totalSeconds: archive.totalSeconds,
      limitSeconds: archive.limitSeconds,
      limitHitAt: archive.limitHitAt,
      apps: archive.apps,
      focusSeconds: archive.focusSeconds,
      lateNightSeconds: archive.lateNightSeconds,
      lateNightApps: archive.lateNightApps,
    );
  }

  @override
  Future<void> clearPendingArchives() => _platform.clearPendingArchives();

  @override
  Future<List<HistoryDay>> loadDays({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!end.isAfter(start)) return const [];

    final startKey = localDateKey(start);
    final endKey = localDateKey(end);

    final summaries =
        await (_database.select(_database.dailySummaries)
              ..where(
                (row) =>
                    row.date.isBiggerOrEqualValue(startKey) &
                    row.date.isSmallerThanValue(endKey),
              )
              ..orderBy([(row) => OrderingTerm(expression: row.date)]))
            .get();
    if (summaries.isEmpty) return const [];

    final usageRows =
        await (_database.select(_database.dailyUsages)..where(
              (row) =>
                  row.date.isBiggerOrEqualValue(startKey) &
                  row.date.isSmallerThanValue(endKey),
            ))
            .get();

    final appsByDate = <String, Map<String, int>>{};
    final lateNightByDate = <String, Map<String, int>>{};
    for (final row in usageRows) {
      (appsByDate[row.date] ??= {})[row.packageName] = row.totalSeconds;
      if (row.lateNightSeconds > 0) {
        (lateNightByDate[row.date] ??= {})[row.packageName] =
            row.lateNightSeconds;
      }
    }

    final days = <HistoryDay>[];
    for (final row in summaries) {
      final date = parseLocalDateKey(row.date);
      if (date == null) continue;
      days.add(
        HistoryDay(
          date: date,
          totalSeconds: row.totalSeconds,
          limitSeconds: row.limitSeconds,
          limitHitAt: row.limitHitAt,
          apps: Map.unmodifiable(appsByDate[row.date] ?? const {}),
          focusSeconds: row.focusSeconds,
          lateNightSeconds: row.lateNightSeconds,
          lateNightApps: Map.unmodifiable(
            lateNightByDate[row.date] ?? const {},
          ),
        ),
      );
    }
    return List.unmodifiable(days);
  }
}
