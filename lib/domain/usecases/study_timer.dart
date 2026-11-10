import '../../core/utils/day_window.dart';
import '../entities/usage_settings.dart';

/// Daily focus timer rules.
///
/// Focus time is cumulative for one local day. A run contributes only while it
/// is actually running; a paused timer keeps its remaining countdown but stops
/// adding focus seconds. The daily goal and the optional missed-goal block are
/// separate from the one-off study lock in [UsageSettings.studyEndsAt].
const int maxFocusGoalMinutes = 10 * 60;
const int maxFocusSessionMinutes = 8 * 60;
const int minFocusSessionMinutes = 5;
const int defaultFocusCutoffMinutes = 20 * 60;

/// Focus seconds completed today, including the running timer's elapsed part.
int focusSecondsForToday(UsageSettings settings, DateTime now) {
  final todayStart = startOfLocalDay(now);
  final base = settings.focusDate == localDateKey(now)
      ? settings.focusSecondsToday
      : 0;

  final sessionStart = settings.focusSessionStartedAt;
  final sessionEnd = settings.focusSessionEndsAt;
  if (sessionStart == null || sessionEnd == null) return base;

  final from = sessionStart.isAfter(todayStart) ? sessionStart : todayStart;
  final cappedEnd = sessionEnd.isBefore(now) ? sessionEnd : now;
  if (!cappedEnd.isAfter(from)) return base;
  return base + cappedEnd.difference(from).inSeconds;
}

/// True while the focus timer has started and has not reached its end.
bool isFocusSessionRunning(UsageSettings settings, DateTime now) {
  final start = settings.focusSessionStartedAt;
  final end = settings.focusSessionEndsAt;
  return start != null &&
      end != null &&
      end.isAfter(now) &&
      !now.isBefore(start);
}

/// True when the timer is paused with time left on the clock.
bool isFocusSessionPaused(UsageSettings settings, DateTime now) =>
    settings.focusSessionStartedAt == null &&
    settings.focusSessionEndsAt == null &&
    settings.focusSessionRemainingSeconds > 0;

/// Seconds left in the focus timer, whether it is running or paused.
int focusSessionRemainingSeconds(UsageSettings settings, DateTime now) {
  final end = settings.focusSessionEndsAt;
  if (end != null && settings.focusSessionStartedAt != null) {
    final remaining = end.difference(now).inSeconds;
    return remaining < 0 ? 0 : remaining;
  }
  return settings.focusSessionRemainingSeconds;
}

/// Local time at which the missed-goal block starts on [moment]'s day.
DateTime focusCutoffFor(DateTime moment, int cutoffMinutes) {
  final safe = cutoffMinutes.clamp(0, 24 * 60 - 1);
  return DateTime(moment.year, moment.month, moment.day, safe ~/ 60, safe % 60);
}

/// True when a goal has been configured.
bool hasFocusGoal(UsageSettings settings) => settings.focusGoalMinutes > 0;

/// True once today's focus total reaches the configured goal.
bool isFocusGoalMet(UsageSettings settings, DateTime now) {
  if (!hasFocusGoal(settings)) return false;
  return focusSecondsForToday(settings, now) >= settings.focusGoalMinutes * 60;
}

/// True when the missed-goal block is in force.
///
/// The block starts at [UsageSettings.focusCutoffMinutes] and lasts until local
/// midnight. It only exists while automation is enabled and a goal is set.
/// Completing focus time can lift it early because the elapsed part of a running
/// session counts immediately.
bool isFocusGoalBlockActive(UsageSettings settings, DateTime now) {
  if (!settings.focusAutoBlockEnabled || !hasFocusGoal(settings)) return false;
  if (now.isBefore(focusCutoffFor(now, settings.focusCutoffMinutes))) {
    return false;
  }
  return !isFocusGoalMet(settings, now);
}

/// End of the missed-goal block: the next local midnight.
DateTime focusGoalBlockEnd(DateTime now) => nextLocalMidnight(now);
