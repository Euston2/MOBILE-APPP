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

  /// Seconds used between local 00:00 and 08:00.
  IntColumn get lateNightSeconds => integer().withDefault(const Constant(0))();

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

  /// Focus timer seconds completed on the day.
  IntColumn get focusSeconds => integer().withDefault(const Constant(0))();

  /// Combined social-app seconds used between local 00:00 and 08:00.
  IntColumn get lateNightSeconds => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// Reader source definitions and the user's enabled/topic choices.
///
/// The bundled `assets/reader/sources.json` is the editable catalogue; this
/// table stores the choices that must survive an app update.
@DataClassName('ReaderSourceRow')
class ReaderSources extends Table {
  @override
  String get tableName => 'sources';

  TextColumn get id => text()();

  TextColumn get name => text()();

  /// Wire value from [ReaderSourceKind]: rss, hackerNews or devTo.
  TextColumn get kind => text()();

  TextColumn get feedUrl => text().nullable()();

  TextColumn get siteUrl => text()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// JSON array of selected topic IDs.
  TextColumn get topicsJson => text().withDefault(const Constant('[]'))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastFetchedAt => dateTime().nullable()();

  TextColumn get lastError => text().nullable()();

  TextColumn get etag => text().nullable()();

  TextColumn get lastModified => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Locally cached Reader articles.
///
/// `pickDate` and `pickRank` freeze the daily list. They are not user-visible
/// state, but they stop a later refresh from growing a list after it is opened.
@DataClassName('ReaderArticleRow')
class ReaderArticles extends Table {
  @override
  String get tableName => 'articles';

  TextColumn get id => text()();

  TextColumn get sourceId => text()();

  /// Snapshot used for attribution if the source row is edited later.
  TextColumn get sourceName => text()();

  TextColumn get title => text()();

  TextColumn get url => text()();

  TextColumn get excerpt => text().withDefault(const Constant(''))();

  TextColumn get contentHtml => text().nullable()();

  IntColumn get readingMinutes => integer().withDefault(const Constant(1))();

  DateTimeColumn get publishedAt => dateTime().nullable()();

  DateTimeColumn get fetchedAt => dateTime()();

  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  TextColumn get pickDate => text().nullable()();

  IntColumn get pickRank => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {url},
  ];
}

@DataClassName('ReaderBookmarkRow')
class ReaderBookmarks extends Table {
  @override
  String get tableName => 'bookmarks';

  TextColumn get articleId => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {articleId};
}

/// Seconds spent in native article screens, aggregated per local day/article.
@DataClassName('ReadingSessionRow')
class ReadingSessions extends Table {
  @override
  String get tableName => 'reading_sessions';

  TextColumn get date => text()();

  TextColumn get articleId => text()();

  IntColumn get seconds => integer()();

  @override
  Set<Column<Object>> get primaryKey => {date, articleId};
}

/// Local SQLite database (drift).
///
/// Settings and lock state deliberately live in `shared_preferences` (they are
/// a handful of scalars read on every tick of the service); everything that
/// grows over time goes here.
@DriftDatabase(
  tables: [
    MonitoredApps,
    DailyUsages,
    DailySummaries,
    ReaderSources,
    ReaderArticles,
    ReaderBookmarks,
    ReadingSessions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// In-memory instance for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Stage 4: scheduled selection changes.
        await m.addColumn(monitoredApps, monitoredApps.pendingEnabled);
      }
      if (from < 3) {
        // Focus timer and late-night usage analytics.
        await m.addColumn(dailyUsages, dailyUsages.lateNightSeconds);
        await m.addColumn(dailySummaries, dailySummaries.focusSeconds);
        await m.addColumn(dailySummaries, dailySummaries.lateNightSeconds);
      }
      if (from < 4) {
        // Reader cache, sources, bookmarks and reading-time sessions.
        await m.createTable(readerSources);
        await m.createTable(readerArticles);
        await m.createTable(readerBookmarks);
        await m.createTable(readingSessions);
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
    int focusSeconds = 0,
    int lateNightSeconds = 0,
    Map<String, int> lateNightApps = const {},
  }) async {
    await transaction(() async {
      await into(dailySummaries).insertOnConflictUpdate(
        DailySummariesCompanion.insert(
          date: date,
          totalSeconds: totalSeconds,
          limitSeconds: limitSeconds,
          limitHitAt: Value(limitHitAt),
          focusSeconds: Value(focusSeconds),
          lateNightSeconds: Value(lateNightSeconds),
        ),
      );
      for (final entry in apps.entries) {
        await into(dailyUsages).insertOnConflictUpdate(
          DailyUsagesCompanion.insert(
            date: date,
            packageName: entry.key,
            totalSeconds: entry.value,
            lateNightSeconds: Value(lateNightApps[entry.key] ?? 0),
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
