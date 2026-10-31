/// One archived local day, as written by the native midnight reset and imported
/// into drift by [HistoryRepository].
class DailyArchive {
  const DailyArchive({
    required this.date,
    required this.totalSeconds,
    required this.limitSeconds,
    required this.apps,
    this.limitHitAt,
  });

  /// Local calendar date, `yyyy-MM-dd`.
  final String date;

  /// Combined seconds across the apps that were monitored that day.
  final int totalSeconds;

  /// The daily limit that applied that day (0 when none).
  final int limitSeconds;

  /// When the limit was hit that day, or null when it was not.
  final DateTime? limitHitAt;

  /// Seconds per monitored package. Only positive entries are kept.
  final Map<String, int> apps;

  @override
  String toString() =>
      'DailyArchive($date, total: ${totalSeconds}s, apps: ${apps.length})';
}
