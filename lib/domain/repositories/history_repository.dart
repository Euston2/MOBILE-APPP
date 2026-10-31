import '../entities/daily_archive.dart';
import '../entities/history_day.dart';

/// Contract for archived daily history.
///
/// The native reset writes finished days to a small native queue because drift
/// (SQLite) is owned by Dart. This repository drains that queue into the
/// database and reads the finished days back for the history screen.
abstract interface class HistoryRepository {
  /// Archives produced by the native reset that Dart has not imported yet.
  Future<List<DailyArchive>> readPendingArchives();

  /// Inserts or replaces the day's summary and per-app rows.
  Future<void> saveArchive(DailyArchive archive);

  /// Clears the native queue after a successful import.
  Future<void> clearPendingArchives();

  /// Archived days in `[start, end)`, oldest first.
  ///
  /// [start] and [end] are local midnights; implementations compare calendar
  /// keys so the query is not affected by the current time of day.
  Future<List<HistoryDay>> loadDays({
    required DateTime start,
    required DateTime end,
  });
}
