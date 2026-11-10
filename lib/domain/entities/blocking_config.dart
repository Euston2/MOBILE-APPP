/// The configuration the native blocking service enforces.
///
/// Dart owns the policy (which apps, what limit, is the lock active); the
/// service only reads this snapshot. It is rebuilt whenever settings or the
/// monitored-app list change and pushed over the platform channel, where Kotlin
/// caches it so blocking keeps working after the Flutter process is killed.
///
/// A scheduled change is sent as a complete second configuration
/// ([pendingPackages] + [pendingLimitSeconds] + [pendingEffectiveAt]): Kotlin
/// switches to it when the clock reaches the effective instant, so the next
/// day's limit is enforced even if Flutter never runs at midnight.
class BlockingConfig {
  const BlockingConfig({
    required this.monitoredPackages,
    required this.dailyLimitSeconds,
    required this.isLocked,
    required this.nextResetAt,
    this.pendingPackages = const {},
    this.pendingLimitSeconds = 0,
    this.pendingEffectiveAt,
    this.lockedAt,
    this.overnightLockEnabled = false,
    this.studyEndsAt,
    this.focusGoalSeconds = 0,
    this.focusAutoBlockEnabled = false,
    this.focusCutoffMinuteOfDay = 20 * 60,
    this.focusBaseSeconds = 0,
    this.focusDayStart,
    this.focusSessionStartedAt,
    this.focusSessionEndsAt,
  });

  /// Apps monitored today.
  final Set<String> monitoredPackages;

  /// Combined limit that applies today. 0 means "no limit".
  final int dailyLimitSeconds;

  /// Apps monitored from [pendingEffectiveAt] onwards.
  final Set<String> pendingPackages;

  /// Limit that applies from [pendingEffectiveAt] onwards (0 = none).
  final int pendingLimitSeconds;

  /// Local midnight at which the pending configuration takes over.
  final DateTime? pendingEffectiveAt;

  final bool isLocked;

  /// When the current lock was stamped.
  final DateTime? lockedAt;

  /// Local midnight at which [isLocked] expires.
  final DateTime nextResetAt;

  /// Recurring hard block from local midnight to 08:00.
  final bool overnightLockEnabled;

  /// End of the current study session, or null when none is running.
  final DateTime? studyEndsAt;

  /// Daily focus goal in seconds; 0 means no goal.
  ///
  /// The native watcher receives the goal, the cutoff and the running session
  /// clock so it can enforce the missed-goal block even when Flutter is asleep.
  final int focusGoalSeconds;

  /// Whether missing the daily goal should block selected apps.
  final bool focusAutoBlockEnabled;

  /// Local minute of day (0-1439) at which the missed-goal block starts.
  final int focusCutoffMinuteOfDay;

  /// Focus seconds already banked for [focusDayStart].
  final int focusBaseSeconds;

  /// Local midnight of the day [focusBaseSeconds] belongs to.
  final DateTime? focusDayStart;

  /// Start/end of the running focus timer, or null when idle/paused.
  final DateTime? focusSessionStartedAt;
  final DateTime? focusSessionEndsAt;

  bool get hasPendingConfig =>
      pendingEffectiveAt != null &&
      pendingLimitSeconds > 0 &&
      pendingPackages.isNotEmpty;

  bool get hasOvernightFocus =>
      overnightLockEnabled && monitoredPackages.isNotEmpty;

  bool get hasStudyFocus => studyEndsAt != null && monitoredPackages.isNotEmpty;

  bool get hasFocusGoal =>
      focusAutoBlockEnabled &&
      focusGoalSeconds > 0 &&
      monitoredPackages.isNotEmpty;

  /// Focus seconds for the local day containing [now], including the running
  /// session's elapsed part. This mirrors the Dart domain calculation.
  int focusSecondsAt(DateTime now) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final base =
        focusDayStart != null &&
            focusDayStart!.year == now.year &&
            focusDayStart!.month == now.month &&
            focusDayStart!.day == now.day
        ? focusBaseSeconds
        : 0;

    final start = focusSessionStartedAt;
    final end = focusSessionEndsAt;
    if (start == null || end == null) return base;

    final from = start.isAfter(todayStart) ? start : todayStart;
    final to = end.isBefore(now) ? end : now;
    if (!to.isAfter(from)) return base;
    return base + to.difference(from).inSeconds;
  }

  /// True after the cutoff when automation is on and the goal is still short.
  bool isFocusGoalBlockActive(DateTime now) {
    if (!hasFocusGoal) return false;
    final cutoffMinutes = focusCutoffMinuteOfDay.clamp(0, 24 * 60 - 1);
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
      cutoffMinutes ~/ 60,
      cutoffMinutes % 60,
    );
    if (now.isBefore(cutoff)) return false;
    return focusSecondsAt(now) < focusGoalSeconds;
  }

  /// Nothing to enforce: no daily limit, scheduled limit or focus lock.
  bool get isActive =>
      (dailyLimitSeconds > 0 && monitoredPackages.isNotEmpty) ||
      hasPendingConfig ||
      hasOvernightFocus ||
      hasStudyFocus ||
      hasFocusGoal;

  @override
  String toString() =>
      'BlockingConfig(apps: ${monitoredPackages.length}, '
      'limit: ${dailyLimitSeconds}s, pendingApps: ${pendingPackages.length}, '
      'pendingLimit: ${pendingLimitSeconds}s, locked: $isLocked, '
      'overnight: $overnightLockEnabled, '
      'studyUntil: ${studyEndsAt?.toIso8601String()}, '
      'focusGoal: ${focusGoalSeconds}s, '
      'focusBlock: $focusAutoBlockEnabled, '
      'focusToday: ${focusBaseSeconds}s)';
}
