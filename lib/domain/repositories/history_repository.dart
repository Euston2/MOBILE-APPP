import '../entities/daily_archive.dart';

/// Contract for the history archive written at midnight.
///
/// The native reset writes finished days to a small native queue because drift
/// (SQLite) is owned by Dart. This repository drains that queue into the
/// database and exposes the write used by tests.
abstract interface class HistoryRepository {
  /// Archives produced by the native reset that Dart has not imported yet.
  Future<List<DailyArchive>> readPendingArchives();

  /// Inserts or replaces the day's summary and per-app rows.
  Future<void> saveArchive(DailyArchive archive);

  /// Clears the native queue after a successful import.
  Future<void> clearPendingArchives();
}
