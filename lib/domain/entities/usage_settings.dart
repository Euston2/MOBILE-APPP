import '../../core/utils/day_window.dart';

/// Persisted user settings and lock state.
///
/// Stored in `shared_preferences` (a handful of scalars) rather than SQLite:
/// the background service reads these on every check, and prefs reads are cheap.
class UsageSettings {
  const UsageSettings({
    required this.dailyLimitSeconds,
    required this.isLocked,
    required this.lockedAt,
    required this.nextResetAt,
    required this.onboardingCompleted,
  });

  /// Defaults for a fresh install: no limit, unlocked, reset at next midnight.
  factory UsageSettings.initial(DateTime now) => UsageSettings(
    dailyLimitSeconds: 0,
    isLocked: false,
    lockedAt: null,
    nextResetAt: nextLocalMidnight(now),
    onboardingCompleted: false,
  );

  /// Combined daily limit for the monitored apps. 0 means "no limit set".
  final int dailyLimitSeconds;

  final bool isLocked;

  /// When the limit was hit (Stage 4). Null while unlocked.
  final DateTime? lockedAt;

  /// Next local midnight; the lock cannot be cleared before this instant, even
  /// if an alarm was missed (Stage 4).
  final DateTime nextResetAt;

  final bool onboardingCompleted;

  bool get hasLimit => dailyLimitSeconds > 0;

  UsageSettings copyWith({
    int? dailyLimitSeconds,
    bool? isLocked,
    DateTime? lockedAt,
    bool clearLockedAt = false,
    DateTime? nextResetAt,
    bool? onboardingCompleted,
  }) {
    return UsageSettings(
      dailyLimitSeconds: dailyLimitSeconds ?? this.dailyLimitSeconds,
      isLocked: isLocked ?? this.isLocked,
      lockedAt: clearLockedAt ? null : (lockedAt ?? this.lockedAt),
      nextResetAt: nextResetAt ?? this.nextResetAt,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  String toString() =>
      'UsageSettings(limit: ${dailyLimitSeconds}s, locked: $isLocked, '
      'reset: ${nextResetAt.toIso8601String()})';
}
