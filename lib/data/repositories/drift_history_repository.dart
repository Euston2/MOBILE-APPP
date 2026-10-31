import '../../domain/entities/daily_archive.dart';
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

      final limit = item['limitSeconds'];
      final hitAtMs = item['limitHitAtMs'];
      archives.add(
        DailyArchive(
          date: date,
          totalSeconds: total.toInt(),
          limitSeconds: limit is num ? limit.toInt() : 0,
          limitHitAt: hitAtMs is num && hitAtMs > 0
              ? DateTime.fromMillisecondsSinceEpoch(hitAtMs.toInt())
              : null,
          apps: Map.unmodifiable(apps),
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
    );
  }

  @override
  Future<void> clearPendingArchives() => _platform.clearPendingArchives();
}
