import '../../core/utils/day_window.dart';
import '../entities/usage_settings.dart';

/// Applies time-based settings transitions.
///
/// This is the single place where the "next day" and "lock until midnight"
/// rules live, so the app behaves identically whether it is opened at 10:00,
/// exactly at 00:00, or days after an alarm was missed:
///
/// - a scheduled limit becomes active once `now >= pending_effective_at`;
/// - a lock is cleared once `now >= next_reset_at`.
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

  if (result.isLocked && !now.isBefore(result.nextResetAt)) {
    result = result.copyWith(
      isLocked: false,
      clearLockedAt: true,
      nextResetAt: nextLocalMidnight(now),
    );
  }

  return result;
}
