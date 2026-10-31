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
