/// One archived local day, as written by the native midnight reset and imported
/// into drift by [HistoryRepository].
class DailyArchive {
  const DailyArchive({
    required this.date,
    required this.totalSeconds,
    required this.limitSeconds,
    required this.apps,
    this.limitHitAt,
    this.focusSeconds = 0,
    this.lateNightSeconds = 0,
    this.lateNightApps = const {},
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

  /// Focus seconds accumulated on this finished day.
  final int focusSeconds;

  /// Social-app seconds used between local 00:00 and 08:00.
  final int lateNightSeconds;

  /// Late-night seconds per monitored package.
  final Map<String, int> lateNightApps;

  @override
  String toString() =>
      'DailyArchive($date, total: ${totalSeconds}s, focus: ${focusSeconds}s, '
      'lateNight: ${lateNightSeconds}s, apps: ${apps.length})';
}
