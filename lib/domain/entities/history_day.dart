import '../../core/utils/day_window.dart';

/// One finished local day as read from the history tables.
///
/// [date] is local midnight. The row only exists once the midnight reset has
/// archived the day, so today's live usage is never part of history.
class HistoryDay {
  const HistoryDay({
    required this.date,
    required this.totalSeconds,
    required this.limitSeconds,
    this.limitHitAt,
    this.apps = const {},
    this.focusSeconds = 0,
    this.lateNightSeconds = 0,
    this.lateNightApps = const {},
    this.readingSeconds = 0,
  });

  final DateTime date;

  /// Combined seconds across the apps that were monitored that day.
  final int totalSeconds;

  /// The daily limit that applied that day (0 when none).
  final int limitSeconds;

  /// When the limit was hit, or null when it was not.
  final DateTime? limitHitAt;

  /// Seconds per monitored package, only positive entries.
  final Map<String, int> apps;

  /// Focus seconds completed on this day.
  final int focusSeconds;

  /// Social-app seconds used between local 00:00 and 08:00.
  final int lateNightSeconds;

  /// Late-night seconds per monitored package, only positive entries.
  final Map<String, int> lateNightApps;

  /// Seconds spent reading articles in the in-app Reader on this day.
  ///
  /// Reading sessions are stored separately from social usage, so this does not
  /// count towards any limit.
  final int readingSeconds;

  String get dateKey => localDateKey(date);

  bool get hasUsage => totalSeconds > 0;

  bool get hasFocus => focusSeconds > 0;

  bool get hasLateNight => lateNightSeconds > 0;

  /// True when the Reader recorded time on this day.
  bool get hasReading => readingSeconds > 0;

  bool get hasActivity => hasUsage || hasFocus || hasLateNight || hasReading;

  /// Returns a copy with the Reader total for the same day attached.
  HistoryDay withReading(int seconds) => HistoryDay(
    date: date,
    totalSeconds: totalSeconds,
    limitSeconds: limitSeconds,
    limitHitAt: limitHitAt,
    apps: apps,
    focusSeconds: focusSeconds,
    lateNightSeconds: lateNightSeconds,
    lateNightApps: lateNightApps,
    readingSeconds: seconds,
  );

  bool get hasLimit => limitSeconds > 0;

  /// True when the day had a limit and reached or passed it.
  bool get hitLimit => hasLimit && totalSeconds >= limitSeconds;

  /// Seconds spent over the limit (0 when under it or no limit).
  int get overSeconds {
    if (!hasLimit || totalSeconds <= limitSeconds) return 0;
    return totalSeconds - limitSeconds;
  }

  /// Seconds still available under the limit (0 when no limit or over it).
  int get remainingSeconds {
    if (!hasLimit || totalSeconds >= limitSeconds) return 0;
    return limitSeconds - totalSeconds;
  }

  @override
  String toString() =>
      'HistoryDay($dateKey, total: ${totalSeconds}s, limit: ${limitSeconds}s, '
      'focus: ${focusSeconds}s, lateNight: ${lateNightSeconds}s)';
}
