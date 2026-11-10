import '../../core/utils/focus_window.dart';
import '../entities/usage_settings.dart';
import 'study_timer.dart';

/// True while the one-off study session is running.
bool isStudyLockActive(UsageSettings settings, DateTime now) {
  final endsAt = settings.studyEndsAt;
  return endsAt != null && endsAt.isAfter(now);
}

/// True while a focus rule currently prevents the selected apps opening.
///
/// This includes the automatic missed-goal block: once the cutoff passes with
/// focus still short of the goal, the user must not be able to relax the limit
/// or app selection. Starting a focus timer remains available because that is
/// how the block is cleared early.
bool isFocusLockActive(UsageSettings settings, DateTime now) =>
    isStudyLockActive(settings, now) ||
    (settings.overnightLockEnabled && isOvernightLockWindow(now)) ||
    isFocusGoalBlockActive(settings, now);

/// False while the overnight window is running, because it cannot be stopped
/// early. Outside the window (or while the toggle is already off) it is free to
/// change.
bool canTurnOffOvernightLock(UsageSettings settings, DateTime now) =>
    !(settings.overnightLockEnabled && isOvernightLockWindow(now));

/// End of the focus lock currently in force, or null when neither is active.
///
/// A study session wins over the overnight window because it is the more
/// specific commitment the user just made.
DateTime? activeFocusLockEnd(UsageSettings settings, DateTime now) {
  if (isStudyLockActive(settings, now)) return settings.studyEndsAt;
  if (isFocusGoalBlockActive(settings, now)) return focusGoalBlockEnd(now);
  if (settings.overnightLockEnabled && isOvernightLockWindow(now)) {
    return overnightLockEndFor(now);
  }
  return null;
}
