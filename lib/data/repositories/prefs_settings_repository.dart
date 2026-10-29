import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/day_window.dart';
import '../../domain/entities/usage_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Settings and lock state in `shared_preferences`.
///
/// Keys mirror the `settings(...)` columns from the data model. Values are
/// scalars, so prefs are a better fit than SQLite: the service reads them on
/// every foreground check and they survive process death.
class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String keyDailyLimitSeconds = 'settings.daily_limit_seconds';
  static const String keyIsLocked = 'settings.is_locked';
  static const String keyLockedAt = 'settings.locked_at';
  static const String keyNextResetAt = 'settings.next_reset_at';
  static const String keyOnboardingCompleted = 'settings.onboarding_completed';

  @override
  Future<UsageSettings> load() async {
    final now = DateTime.now();
    final nextResetAtMs = _prefs.getInt(keyNextResetAt);
    final lockedAtMs = _prefs.getInt(keyLockedAt);

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
    await _prefs.setBool(keyOnboardingCompleted, settings.onboardingCompleted);
  }
}
