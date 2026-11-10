import '../../core/utils/day_window.dart';
import '../entities/usage_settings.dart';

/// Applies time-based settings transitions.
///
/// This is the single place where the "next day" and "lock until midnight"
/// rules live, so the app behaves identically whether it is opened at 10:00,
/// exactly at 00:00, or days after an alarm was missed:
///
/// - a scheduled limit becomes active once `now >= pending_effective_at`;
/// - a lock is cleared once `now >= next_reset_at`;
/// - an expired study session is cleared so the focus UI turns itself off;
/// - a finished focus timer is banked into today's focus total;
/// - the reset timestamp rolls forward to the coming midnight once the stored
///   one is in the past, even when no lock was active.
///
/// The reset timestamp describes the next boundary, not the last one. Keeping it
/// current makes the saved daily limit recur on every later day without the user
/// opening the picker or saving again.
///
/// The scheduled effective date is intentionally kept after the limit is
/// applied: `MonitoredApp.pendingEnabled` uses the same date, and both
/// reconcilers may run in either order.
UsageSettings reconcileSettings(UsageSettings settings, DateTime now) {
  var result = settings;

  final effectiveAt = settings.pendingEffectiveAt;
  final pendingLimit = settings.pendingLimitSeconds;
  if (effectiveAt != null &&
      pendingLimit != null &&
      !now.isBefore(effectiveAt)) {
    result = result.copyWith(
      dailyLimitSeconds: pendingLimit,
      clearPendingLimit: true,
    );
  }

  final studyEndsAt = result.studyEndsAt;
  if (studyEndsAt != null && !now.isBefore(studyEndsAt)) {
    result = result.copyWith(clearStudyEndsAt: true);
  }

  // Bank a focus timer that finished while the app was closed. Only the part
  // that falls on the current local day is added here; a session that crosses
  // midnight was archived by the native side from the old config.
  final focusStart = result.focusSessionStartedAt;
  final focusEnd = result.focusSessionEndsAt;
  if (focusStart != null && focusEnd != null && !now.isBefore(focusEnd)) {
    final todayStart = startOfLocalDay(now);
    final from = focusStart.isAfter(todayStart) ? focusStart : todayStart;
    final to = focusEnd.isBefore(now) ? focusEnd : now;
    final elapsed = to.isAfter(from) ? to.difference(from).inSeconds : 0;
    final base = result.focusDate == localDateKey(now)
        ? result.focusSecondsToday
        : 0;
    result = result.copyWith(
      focusDate: localDateKey(now),
      focusSecondsToday: base + elapsed,
      clearFocusSessionStartedAt: true,
      clearFocusSessionEndsAt: true,
      focusSessionRemainingSeconds: 0,
    );
  }

  if (!now.isBefore(result.nextResetAt)) {
    final wasLocked = result.isLocked;
    result = result.copyWith(
      isLocked: false,
      clearLockedAt: wasLocked,
      nextResetAt: nextLocalMidnight(now),
    );
  }

  return result;
}
