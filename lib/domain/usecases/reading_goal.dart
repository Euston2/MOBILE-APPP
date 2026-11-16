import '../../core/utils/day_window.dart';
import '../entities/usage_settings.dart';

/// Daily reading-goal automation.
///
/// Reading time lives in drift/Reader sessions rather than prefs, so callers
/// pass today's total in. The block itself is time-based: after the cutoff, if
/// the total is still short, the selected social apps stay blocked until the
/// goal is met or the day resets.
const int maxReadingGoalMinutes = 8 * 60;
const int defaultReadingCutoffMinutes = 20 * 60;

bool hasReadingGoal(UsageSettings settings) => settings.readingGoalMinutes > 0;

int readingGoalSeconds(UsageSettings settings) =>
    settings.readingGoalMinutes * 60;

/// Local time at which the missed-reading block starts on [moment]'s day.
DateTime readingCutoffFor(DateTime moment, int cutoffMinutes) {
  final safe = cutoffMinutes.clamp(0, 24 * 60 - 1);
  return DateTime(moment.year, moment.month, moment.day, safe ~/ 60, safe % 60);
}

bool isReadingGoalMet(UsageSettings settings, int readingSecondsToday) {
  if (!hasReadingGoal(settings)) return false;
  return readingSecondsToday >= readingGoalSeconds(settings);
}

bool isReadingGoalBlockActive(
  UsageSettings settings,
  DateTime now,
  int readingSecondsToday,
) {
  if (!settings.readingAutoBlockEnabled || !hasReadingGoal(settings)) {
    return false;
  }
  if (now.isBefore(readingCutoffFor(now, settings.readingCutoffMinutes))) {
    return false;
  }
  return !isReadingGoalMet(settings, readingSecondsToday);
}

/// End of the missed-reading block: the next local midnight.
DateTime readingGoalBlockEnd(DateTime now) => nextLocalMidnight(now);

/// The amount still missing today, clamped at zero.
int readingGoalRemainingSeconds(
  UsageSettings settings,
  int readingSecondsToday,
) {
  final remaining = readingGoalSeconds(settings) - readingSecondsToday;
  return remaining < 0 ? 0 : remaining;
}
