import '../../core/utils/day_window.dart';

/// Persisted user settings and lock state.
///
/// Stored in `shared_preferences` (a handful of scalars) rather than SQLite:
/// the background service reads these on every check, and prefs reads are cheap.
///
/// Stage 4 adds two scheduled-change fields:
/// - [pendingLimitSeconds] is the limit the user picked while a limit was
///   already active today. It becomes [dailyLimitSeconds] at
///   [pendingEffectiveAt] (the next local midnight).
/// - [pendingEffectiveAt] is kept after the limit is applied because it is also
///   the effective time for pending app-selection changes (see
///   `MonitoredApp.pendingEnabled`).
class UsageSettings {
  const UsageSettings({
    required this.dailyLimitSeconds,
    required this.isLocked,
    required this.lockedAt,
    required this.nextResetAt,
    required this.onboardingCompleted,
    this.pendingLimitSeconds,
    this.pendingEffectiveAt,
    this.overnightLockEnabled = false,
    this.studyEndsAt,
    this.studyLengthMinutes = 60,
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
  ///
  /// This is the limit that applies *today*; scheduled limits live in
  /// [pendingLimitSeconds].
  final int dailyLimitSeconds;

  final bool isLocked;

  /// When the limit was hit. Null while unlocked.
  final DateTime? lockedAt;

  /// Next local midnight; the lock cannot be cleared before this instant, even
  /// if an alarm was missed.
  final DateTime nextResetAt;

  final bool onboardingCompleted;

  /// Limit that takes effect at [pendingEffectiveAt]. Null when no limit change
  /// is scheduled.
  final int? pendingLimitSeconds;

  /// Local midnight at which pending limit/app changes take effect.
  final DateTime? pendingEffectiveAt;

  /// Recurring block from local midnight to 08:00 every day.
  ///
  /// This is a hard lock while its window is active: the UI and controllers do
  /// not allow turning it off until 08:00.
  final bool overnightLockEnabled;

  /// End of the current study session, or null when no session is running.
  ///
  /// There is deliberately no "stop" action while this is in the future; the
  /// session ends on its own so the user cannot talk themselves out of it.
  final DateTime? studyEndsAt;

  /// Last study duration chosen by the user, in minutes.
  ///
  /// Persisted so the Focus screen can preload a sensible selection next time.
  final int studyLengthMinutes;

  bool get hasLimit => dailyLimitSeconds > 0;

  bool get hasPendingLimit => pendingLimitSeconds != null;

  bool get hasPendingChange => hasPendingLimit;

  UsageSettings copyWith({
    int? dailyLimitSeconds,
    bool? isLocked,
    DateTime? lockedAt,
    bool clearLockedAt = false,
    DateTime? nextResetAt,
    bool? onboardingCompleted,
    int? pendingLimitSeconds,
    bool clearPendingLimit = false,
    DateTime? pendingEffectiveAt,
    bool clearPendingEffectiveAt = false,
    bool? overnightLockEnabled,
    DateTime? studyEndsAt,
    bool clearStudyEndsAt = false,
    int? studyLengthMinutes,
  }) {
    return UsageSettings(
      dailyLimitSeconds: dailyLimitSeconds ?? this.dailyLimitSeconds,
      isLocked: isLocked ?? this.isLocked,
      lockedAt: clearLockedAt ? null : (lockedAt ?? this.lockedAt),
      nextResetAt: nextResetAt ?? this.nextResetAt,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      pendingLimitSeconds: clearPendingLimit
          ? null
          : (pendingLimitSeconds ?? this.pendingLimitSeconds),
      pendingEffectiveAt: clearPendingEffectiveAt
          ? null
          : (pendingEffectiveAt ?? this.pendingEffectiveAt),
      overnightLockEnabled: overnightLockEnabled ?? this.overnightLockEnabled,
      studyEndsAt: clearStudyEndsAt ? null : (studyEndsAt ?? this.studyEndsAt),
      studyLengthMinutes: studyLengthMinutes ?? this.studyLengthMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UsageSettings &&
      other.dailyLimitSeconds == dailyLimitSeconds &&
      other.isLocked == isLocked &&
      other.lockedAt == lockedAt &&
      other.nextResetAt == nextResetAt &&
      other.onboardingCompleted == onboardingCompleted &&
      other.pendingLimitSeconds == pendingLimitSeconds &&
      other.pendingEffectiveAt == pendingEffectiveAt &&
      other.overnightLockEnabled == overnightLockEnabled &&
      other.studyEndsAt == studyEndsAt &&
      other.studyLengthMinutes == studyLengthMinutes;

  @override
  int get hashCode => Object.hash(
    dailyLimitSeconds,
    isLocked,
    lockedAt,
    nextResetAt,
    onboardingCompleted,
    pendingLimitSeconds,
    pendingEffectiveAt,
    overnightLockEnabled,
    studyEndsAt,
    studyLengthMinutes,
  );

  @override
  String toString() =>
      'UsageSettings(limit: ${dailyLimitSeconds}s, locked: $isLocked, '
      'pending: ${pendingLimitSeconds}s @ ${pendingEffectiveAt?.toIso8601String()}, '
      'overnight: $overnightLockEnabled, '
      'studyUntil: ${studyEndsAt?.toIso8601String()}, '
      'reset: ${nextResetAt.toIso8601String()})';
}
