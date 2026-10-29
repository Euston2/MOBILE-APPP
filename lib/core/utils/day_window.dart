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
