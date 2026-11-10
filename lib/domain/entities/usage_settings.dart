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
    this.focusGoalMinutes = 0,
    this.focusAutoBlockEnabled = false,
    this.focusCutoffMinutes = 20 * 60,
    this.focusDate,
    this.focusSecondsToday = 0,
    this.focusSessionStartedAt,
    this.focusSessionEndsAt,
    this.focusSessionRemainingSeconds = 0,
    this.focusSessionLengthMinutes = 25,
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

  /// Daily focus goal in minutes. 0 means no goal is configured.
  ///
  /// Focus time is cumulative across timer sessions and resets at local
  /// midnight. The goal is separate from the one-off [studyEndsAt] lock: the
  /// lock closes apps immediately, while the goal tracks focus over the day.
  final int focusGoalMinutes;

  /// When true, selected apps are blocked after [focusCutoffMinutes] until the
  /// goal is met or the day resets.
  final bool focusAutoBlockEnabled;

  /// Local minute of day (0-1439) at which the missed-goal block starts.
  ///
  /// Defaults to 20:00. It can be any time; a cutoff of 00:00 means the block
  /// applies from the start of the day.
  final int focusCutoffMinutes;

  /// Local calendar date (`yyyy-MM-dd`) that [focusSecondsToday] belongs to.
  ///
  /// Null on a fresh install. The date is kept explicitly so a stale focus
  /// total can never be mistaken for today's progress after midnight.
  final String? focusDate;

  /// Focus seconds banked for [focusDate] from completed/paused timer runs.
  ///
  /// A currently running session is deliberately not added here until it is
  /// paused, stopped or completes; [focusSecondsForToday] adds its elapsed
  /// portion on the fly.
  final int focusSecondsToday;

  /// Start of the running focus timer, or null when the timer is idle/paused.
  final DateTime? focusSessionStartedAt;

  /// Planned end of the running focus timer, or null when idle/paused.
  final DateTime? focusSessionEndsAt;

  /// Seconds left in a paused focus timer. 0 when no timer is paused.
  final int focusSessionRemainingSeconds;

  /// Last focus duration chosen by the user, in minutes.
  final int focusSessionLengthMinutes;

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
    int? focusGoalMinutes,
    bool? focusAutoBlockEnabled,
    int? focusCutoffMinutes,
    String? focusDate,
    bool clearFocusDate = false,
    int? focusSecondsToday,
    DateTime? focusSessionStartedAt,
    bool clearFocusSessionStartedAt = false,
    DateTime? focusSessionEndsAt,
    bool clearFocusSessionEndsAt = false,
    int? focusSessionRemainingSeconds,
    int? focusSessionLengthMinutes,
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
      focusGoalMinutes: focusGoalMinutes ?? this.focusGoalMinutes,
      focusAutoBlockEnabled:
          focusAutoBlockEnabled ?? this.focusAutoBlockEnabled,
      focusCutoffMinutes: focusCutoffMinutes ?? this.focusCutoffMinutes,
      focusDate: clearFocusDate ? null : (focusDate ?? this.focusDate),
      focusSecondsToday: focusSecondsToday ?? this.focusSecondsToday,
      focusSessionStartedAt: clearFocusSessionStartedAt
          ? null
          : (focusSessionStartedAt ?? this.focusSessionStartedAt),
      focusSessionEndsAt: clearFocusSessionEndsAt
          ? null
          : (focusSessionEndsAt ?? this.focusSessionEndsAt),
      focusSessionRemainingSeconds:
          focusSessionRemainingSeconds ?? this.focusSessionRemainingSeconds,
      focusSessionLengthMinutes:
          focusSessionLengthMinutes ?? this.focusSessionLengthMinutes,
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
      other.studyLengthMinutes == studyLengthMinutes &&
      other.focusGoalMinutes == focusGoalMinutes &&
      other.focusAutoBlockEnabled == focusAutoBlockEnabled &&
      other.focusCutoffMinutes == focusCutoffMinutes &&
      other.focusDate == focusDate &&
      other.focusSecondsToday == focusSecondsToday &&
      other.focusSessionStartedAt == focusSessionStartedAt &&
      other.focusSessionEndsAt == focusSessionEndsAt &&
      other.focusSessionRemainingSeconds == focusSessionRemainingSeconds &&
      other.focusSessionLengthMinutes == focusSessionLengthMinutes;

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
    focusGoalMinutes,
    focusAutoBlockEnabled,
    focusCutoffMinutes,
    focusDate,
    focusSecondsToday,
    focusSessionStartedAt,
    focusSessionEndsAt,
    focusSessionRemainingSeconds,
    focusSessionLengthMinutes,
  );

  @override
  String toString() =>
      'UsageSettings(limit: ${dailyLimitSeconds}s, locked: $isLocked, '
      'pending: ${pendingLimitSeconds}s @ ${pendingEffectiveAt?.toIso8601String()}, '
      'overnight: $overnightLockEnabled, '
      'studyUntil: ${studyEndsAt?.toIso8601String()}, '
      'focusGoal: ${focusGoalMinutes}m, focusToday: ${focusSecondsToday}s, '
      'reset: ${nextResetAt.toIso8601String()})';
}
