/// Local-day boundaries used by the usage counter.
///
/// "Today" always starts at 00:00 in the device's current time zone — the same
/// rule the midnight reset uses (Stage 4).
library;

/// 00:00 of the local day that contains [moment].
DateTime startOfLocalDay(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day);

/// 00:00 of the following local day.
DateTime nextLocalMidnight(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day + 1);

/// Time left until the next local midnight (never negative).
Duration untilNextMidnight(DateTime moment) {
  final remaining = nextLocalMidnight(moment).difference(moment);
  return remaining.isNegative ? Duration.zero : remaining;
}

/// Local calendar key (`yyyy-MM-dd`) used by the archived-day tables.
///
/// The same format is written by Kotlin (`DayMath.localDate`), so a string
/// comparison is also a date comparison for rows in one time zone.
String localDateKey(DateTime moment) {
  final year = moment.year.toString().padLeft(4, '0');
  final month = moment.month.toString().padLeft(2, '0');
  final day = moment.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// Splits the half-open interval [start, end) into local-day buckets.
///
/// A reading session that crosses midnight is charged to both days instead of
/// being added to whichever day happened to be active when the screen closed.
/// Seconds are rounded down and empty buckets are omitted.
Map<String, int> secondsByLocalDay(DateTime start, DateTime end) {
  if (!end.isAfter(start)) return const {};

  final totals = <String, int>{};
  var cursor = start;
  while (cursor.isBefore(end)) {
    final midnight = nextLocalMidnight(cursor);
    final segmentEnd = end.isBefore(midnight) ? end : midnight;
    final seconds = segmentEnd.difference(cursor).inSeconds;
    if (seconds > 0) {
      final key = localDateKey(cursor);
      totals[key] = (totals[key] ?? 0) + seconds;
    }
    if (!segmentEnd.isAfter(cursor)) break;
    cursor = segmentEnd;
  }
  return totals;
}

/// Parses a strict `yyyy-MM-dd` key into local midnight.
///
/// Returns null for malformed keys or impossible dates such as `2026-02-30`,
/// so a corrupted row is skipped rather than shown on the wrong day.
DateTime? parseLocalDateKey(String key) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
  if (match == null) return null;

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}
