import '../../core/utils/day_window.dart';
import '../entities/history_day.dart';

/// Aggregate numbers for the selected history window.
///
/// "Tracked" days are days with an archived row and non-zero usage. A day with
/// no archived row may mean zero usage, the phone was off, or Lockout was not
/// running, so it is deliberately excluded from the average instead of being
/// counted as a zero. The UI shows the tracked-day count next to the average.
class HistoryStats {
  const HistoryStats({
    required this.trackedDays,
    required this.totalSeconds,
    required this.averageSeconds,
    required this.limitHitDays,
    required this.underLimitDays,
    this.totalFocusSeconds = 0,
    this.totalLateNightSeconds = 0,
    this.totalReadingSeconds = 0,
  });

  const HistoryStats.empty()
    : trackedDays = 0,
      totalSeconds = 0,
      averageSeconds = 0,
      limitHitDays = 0,
      underLimitDays = 0,
      totalFocusSeconds = 0,
      totalLateNightSeconds = 0,
      totalReadingSeconds = 0;

  final int trackedDays;
  final int totalSeconds;
  final int averageSeconds;
  final int limitHitDays;

  /// Tracked days that had a limit and did not reach it.
  final int underLimitDays;

  /// Focus completed across the window, including focus-only days.
  final int totalFocusSeconds;

  /// Social-app usage between 00:00 and 08:00 across the window.
  final int totalLateNightSeconds;

  /// In-app Reader time across the window.
  final int totalReadingSeconds;
}

/// A padded, chart-ready view of the selected window plus its statistics.
///
/// [days] is always [dayCount] entries, oldest first, ending the day before
/// [endExclusive]. Missing days are zero entries so the chart keeps a stable
/// calendar width; only stored days count towards [stats].
class HistoryReport {
  const HistoryReport({required this.days, required this.stats});

  final List<HistoryDay> days;
  final HistoryStats stats;

  bool get hasData =>
      days.any((day) => day.hasActivity) || stats.totalReadingSeconds > 0;
}

/// Builds the padded report for the window `[endExclusive - dayCount, endExclusive)`.
///
/// [stored] is what the database returned for that window; it may contain fewer
/// days (or none) when Lockout was not running. [readingSecondsByDay] uses local
/// `yyyy-MM-dd` keys and is attached to the matching day, including days that
/// have no archived social usage.
HistoryReport buildHistoryReport({
  required Iterable<HistoryDay> stored,
  required DateTime endExclusive,
  required int dayCount,
  Map<String, int> readingSecondsByDay = const {},
}) {
  assert(dayCount > 0, 'dayCount must be positive');
  if (dayCount <= 0) {
    return const HistoryReport(days: [], stats: HistoryStats.empty());
  }

  final end = startOfLocalDay(endExclusive);
  final byDate = <String, HistoryDay>{
    for (final day in stored) day.dateKey: day,
  };

  final days = <HistoryDay>[];
  for (var offset = dayCount; offset >= 1; offset--) {
    final date = DateTime(end.year, end.month, end.day - offset);
    final key = localDateKey(date);
    final base =
        byDate[key] ?? HistoryDay(date: date, totalSeconds: 0, limitSeconds: 0);
    days.add(base.withReading(readingSecondsByDay[key] ?? 0));
  }

  return HistoryReport(
    days: List.unmodifiable(days),
    stats: summarizeHistory(days),
  );
}

/// Computes totals over archived days with usage.
HistoryStats summarizeHistory(Iterable<HistoryDay> days) {
  var trackedDays = 0;
  var totalSeconds = 0;
  var limitHitDays = 0;
  var underLimitDays = 0;
  var totalFocusSeconds = 0;
  var totalLateNightSeconds = 0;
  var totalReadingSeconds = 0;

  for (final day in days) {
    totalFocusSeconds += day.focusSeconds;
    totalLateNightSeconds += day.lateNightSeconds;
    totalReadingSeconds += day.readingSeconds;
    if (!day.hasUsage) continue;
    trackedDays++;
    totalSeconds += day.totalSeconds;
    if (day.hitLimit) {
      limitHitDays++;
    } else if (day.hasLimit) {
      underLimitDays++;
    }
  }

  return HistoryStats(
    trackedDays: trackedDays,
    totalSeconds: totalSeconds,
    averageSeconds: trackedDays == 0 ? 0 : (totalSeconds / trackedDays).round(),
    limitHitDays: limitHitDays,
    underLimitDays: underLimitDays,
    totalFocusSeconds: totalFocusSeconds,
    totalLateNightSeconds: totalLateNightSeconds,
    totalReadingSeconds: totalReadingSeconds,
  );
}
