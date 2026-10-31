import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Apps the user chose to track. [isEnabled] is the selection that applies
/// today; [pendingEnabled] schedules a change for the next local midnight.
@DataClassName('MonitoredAppRow')
class MonitoredApps extends Table {
  @override
  String get tableName => 'monitored_apps';

  TextColumn get packageName => text()();

  TextColumn get displayName => text()();

  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  /// Null = no scheduled change. True = add at next midnight. False = remove.
  BoolColumn get pendingEnabled => boolean().nullable()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {packageName};
}

/// Per-app totals for one local day. Written at the midnight reset and read by
/// the history screen (Stage 5).
@DataClassName('DailyUsageRow')
class DailyUsages extends Table {
  @override
  String get tableName => 'daily_usage';

  /// Local calendar date as `yyyy-MM-dd`.
  TextColumn get date => text()();

  TextColumn get packageName => text()();

  IntColumn get totalSeconds => integer()();

  @override
  Set<Column<Object>> get primaryKey => {date, packageName};
}

/// One row per day: combined total, the limit that applied, and when the limit
/// was hit (null when it was not).
@DataClassName('DailySummaryRow')
class DailySummaries extends Table {
  @override
  String get tableName => 'daily_summary';

  TextColumn get date => text()();

  IntColumn get totalSeconds => integer()();

  IntColumn get limitSeconds => integer()();

  DateTimeColumn get limitHitAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// Local SQLite database (drift).
///
/// Settings and lock state deliberately live in `shared_preferences` (they are
/// a handful of scalars read on every tick of the service); everything that
/// grows over time goes here.
@DriftDatabase(tables: [MonitoredApps, DailyUsages, DailySummaries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// In-memory instance for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Stage 4: scheduled selection changes.
        await m.addColumn(monitoredApps, monitoredApps.pendingEnabled);
      }
    },
  );

  /// Opens the on-device database file.
  static AppDatabase open() => AppDatabase(_openConnection());

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(p.join(directory.path, 'lockout.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  Future<List<MonitoredAppRow>> allMonitoredApps() => (select(
    monitoredApps,
  )..orderBy([(t) => OrderingTerm(expression: t.displayName)])).get();

  Future<List<MonitoredAppRow>> enabledMonitoredApps() =>
      (select(monitoredApps)..where((t) => t.isEnabled.equals(true))).get();

  /// Replaces the whole selection atomically.
  Future<void> replaceMonitoredApps(List<MonitoredAppsCompanion> rows) async {
    await transaction(() async {
      await delete(monitoredApps).go();
      await batch((batch) => batch.insertAll(monitoredApps, rows));
    });
  }

  /// Writes one archived day, replacing rows with the same date.
  ///
  /// The native reset can deliver the same archive twice (for example when the
  /// import is retried), so every write is an upsert.
  Future<void> saveDailyArchive({
    required String date,
    required int totalSeconds,
    required int limitSeconds,
    required DateTime? limitHitAt,
    required Map<String, int> apps,
  }) async {
    await transaction(() async {
      await into(dailySummaries).insertOnConflictUpdate(
        DailySummariesCompanion.insert(
          date: date,
          totalSeconds: totalSeconds,
          limitSeconds: limitSeconds,
          limitHitAt: Value(limitHitAt),
        ),
      );
      for (final entry in apps.entries) {
        await into(dailyUsages).insertOnConflictUpdate(
          DailyUsagesCompanion.insert(
            date: date,
            packageName: entry.key,
            totalSeconds: entry.value,
          ),
        );
      }
      // Remove stale per-app rows for this date when an archive is retried
      // with a smaller app set.
      if (apps.isNotEmpty) {
        await (delete(dailyUsages)..where(
              (t) =>
                  t.date.equals(date) &
                  t.packageName.isNotIn(apps.keys.toList()),
            ))
            .go();
      }
    });
  }
}
