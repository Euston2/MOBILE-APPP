import '../../core/utils/focus_window.dart';
import '../entities/usage_settings.dart';

/// True while the one-off study session is running.
bool isStudyLockActive(UsageSettings settings, DateTime now) {
  final endsAt = settings.studyEndsAt;
  return endsAt != null && endsAt.isAfter(now);
}

/// True while either focus lock currently prevents the selected apps opening.
bool isFocusLockActive(UsageSettings settings, DateTime now) =>
    isStudyLockActive(settings, now) ||
    (settings.overnightLockEnabled && isOvernightLockWindow(now));

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
  if (settings.overnightLockEnabled && isOvernightLockWindow(now)) {
    return overnightLockEndFor(now);
  }
  return null;
}
