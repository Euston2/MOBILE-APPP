import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/day_window.dart';
import '../../domain/entities/usage_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/study_timer.dart';

/// Settings and lock state in `shared_preferences`.
///
/// Keys mirror the `settings(...)` columns from the data model. Values are
/// scalars, so prefs are a better fit than SQLite: the service reads them on
/// every foreground check and they survive process death.
///
/// The Kotlin service writes `settings.is_locked`, `settings.locked_at` and
/// `settings.next_reset_at` into this same prefs file (see
/// `FlutterSettings.kt`), which is why [reload] exists: the Dart cache must be
/// refreshed after the app resumes.
class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String keyDailyLimitSeconds = 'settings.daily_limit_seconds';
  static const String keyPendingLimitSeconds = 'settings.pending_limit_seconds';
  static const String keyPendingEffectiveAt = 'settings.pending_effective_at';
  static const String keyIsLocked = 'settings.is_locked';
  static const String keyLockedAt = 'settings.locked_at';
  static const String keyNextResetAt = 'settings.next_reset_at';
  static const String keyOnboardingCompleted = 'settings.onboarding_completed';
  static const String keyOvernightLockEnabled =
      'settings.overnight_lock_enabled';
  static const String keyStudyEndsAt = 'settings.study_ends_at';
  static const String keyStudyLengthMinutes = 'settings.study_length_minutes';
  static const String keyFocusGoalMinutes = 'settings.focus_goal_minutes';
  static const String keyFocusAutoBlockEnabled =
      'settings.focus_auto_block_enabled';
  static const String keyFocusCutoffMinutes = 'settings.focus_cutoff_minutes';
  static const String keyFocusDate = 'settings.focus_date';
  static const String keyFocusSecondsToday = 'settings.focus_seconds_today';
  static const String keyFocusSessionStartedAt =
      'settings.focus_session_started_at';
  static const String keyFocusSessionEndsAt = 'settings.focus_session_ends_at';
  static const String keyFocusSessionRemainingSeconds =
      'settings.focus_session_remaining_seconds';
  static const String keyFocusSessionLengthMinutes =
      'settings.focus_session_length_minutes';

  @override
  Future<UsageSettings> load() async {
    final now = DateTime.now();
    final nextResetAtMs = _prefs.getInt(keyNextResetAt);
    final lockedAtMs = _prefs.getInt(keyLockedAt);
    final pendingLimit = _prefs.getInt(keyPendingLimitSeconds);
    final pendingEffectiveAtMs = _prefs.getInt(keyPendingEffectiveAt);
    final studyEndsAtMs = _prefs.getInt(keyStudyEndsAt);
    final focusSessionStartedAtMs = _prefs.getInt(keyFocusSessionStartedAt);
    final focusSessionEndsAtMs = _prefs.getInt(keyFocusSessionEndsAt);

    return UsageSettings(
      dailyLimitSeconds: _prefs.getInt(keyDailyLimitSeconds) ?? 0,
      isLocked: _prefs.getBool(keyIsLocked) ?? false,
      lockedAt: lockedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lockedAtMs),
      nextResetAt: nextResetAtMs == null
          ? nextLocalMidnight(now)
          : DateTime.fromMillisecondsSinceEpoch(nextResetAtMs),
      onboardingCompleted: _prefs.getBool(keyOnboardingCompleted) ?? false,
      pendingLimitSeconds: pendingLimit,
      pendingEffectiveAt: pendingEffectiveAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(pendingEffectiveAtMs),
      overnightLockEnabled: _prefs.getBool(keyOvernightLockEnabled) ?? false,
      studyEndsAt: studyEndsAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(studyEndsAtMs),
      studyLengthMinutes: _prefs.getInt(keyStudyLengthMinutes) ?? 60,
      focusGoalMinutes: _prefs.getInt(keyFocusGoalMinutes) ?? 0,
      focusAutoBlockEnabled: _prefs.getBool(keyFocusAutoBlockEnabled) ?? false,
      focusCutoffMinutes:
          _prefs.getInt(keyFocusCutoffMinutes) ?? defaultFocusCutoffMinutes,
      focusDate: _prefs.getString(keyFocusDate),
      focusSecondsToday: _prefs.getInt(keyFocusSecondsToday) ?? 0,
      focusSessionStartedAt: focusSessionStartedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(focusSessionStartedAtMs),
      focusSessionEndsAt: focusSessionEndsAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(focusSessionEndsAtMs),
      focusSessionRemainingSeconds:
          _prefs.getInt(keyFocusSessionRemainingSeconds) ?? 0,
      focusSessionLengthMinutes:
          _prefs.getInt(keyFocusSessionLengthMinutes) ?? 25,
    );
  }

  @override
  Future<void> save(UsageSettings settings) async {
    await _prefs.setInt(keyDailyLimitSeconds, settings.dailyLimitSeconds);
    await _prefs.setBool(keyIsLocked, settings.isLocked);

    final lockedAt = settings.lockedAt;
    if (lockedAt == null) {
      await _prefs.remove(keyLockedAt);
    } else {
      await _prefs.setInt(keyLockedAt, lockedAt.millisecondsSinceEpoch);
    }

    await _prefs.setInt(
      keyNextResetAt,
      settings.nextResetAt.millisecondsSinceEpoch,
    );

    final pendingLimit = settings.pendingLimitSeconds;
    if (pendingLimit == null) {
      await _prefs.remove(keyPendingLimitSeconds);
    } else {
      await _prefs.setInt(keyPendingLimitSeconds, pendingLimit);
    }

    final pendingEffectiveAt = settings.pendingEffectiveAt;
    if (pendingEffectiveAt == null) {
      await _prefs.remove(keyPendingEffectiveAt);
    } else {
      await _prefs.setInt(
        keyPendingEffectiveAt,
        pendingEffectiveAt.millisecondsSinceEpoch,
      );
    }

    await _prefs.setBool(keyOnboardingCompleted, settings.onboardingCompleted);
    await _prefs.setBool(
      keyOvernightLockEnabled,
      settings.overnightLockEnabled,
    );

    final studyEndsAt = settings.studyEndsAt;
    if (studyEndsAt == null) {
      await _prefs.remove(keyStudyEndsAt);
    } else {
      await _prefs.setInt(keyStudyEndsAt, studyEndsAt.millisecondsSinceEpoch);
    }
    await _prefs.setInt(keyStudyLengthMinutes, settings.studyLengthMinutes);

    await _prefs.setInt(keyFocusGoalMinutes, settings.focusGoalMinutes);
    await _prefs.setBool(
      keyFocusAutoBlockEnabled,
      settings.focusAutoBlockEnabled,
    );
    await _prefs.setInt(keyFocusCutoffMinutes, settings.focusCutoffMinutes);
    final focusDate = settings.focusDate;
    if (focusDate == null) {
      await _prefs.remove(keyFocusDate);
    } else {
      await _prefs.setString(keyFocusDate, focusDate);
    }
    await _prefs.setInt(keyFocusSecondsToday, settings.focusSecondsToday);
    final focusStartedAt = settings.focusSessionStartedAt;
    if (focusStartedAt == null) {
      await _prefs.remove(keyFocusSessionStartedAt);
    } else {
      await _prefs.setInt(
        keyFocusSessionStartedAt,
        focusStartedAt.millisecondsSinceEpoch,
      );
    }
    final focusEndsAt = settings.focusSessionEndsAt;
    if (focusEndsAt == null) {
      await _prefs.remove(keyFocusSessionEndsAt);
    } else {
      await _prefs.setInt(
        keyFocusSessionEndsAt,
        focusEndsAt.millisecondsSinceEpoch,
      );
    }
    await _prefs.setInt(
      keyFocusSessionRemainingSeconds,
      settings.focusSessionRemainingSeconds,
    );
    await _prefs.setInt(
      keyFocusSessionLengthMinutes,
      settings.focusSessionLengthMinutes,
    );
  }

  @override
  Future<void> reload() => _prefs.reload();
}
