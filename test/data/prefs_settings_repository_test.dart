import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/data/repositories/prefs_settings_repository.dart';
import 'package:lockout/domain/entities/usage_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PrefsSettingsRepository> freshRepository() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return PrefsSettingsRepository(prefs);
  }

  test('returns defaults on a fresh install', () async {
    final repository = await freshRepository();

    final settings = await repository.load();

    expect(settings.dailyLimitSeconds, 0);
    expect(settings.hasLimit, isFalse);
    expect(settings.isLocked, isFalse);
    expect(settings.lockedAt, isNull);
    expect(settings.onboardingCompleted, isFalse);
    expect(settings.nextResetAt.isAfter(DateTime.now()), isTrue);
    expect(settings.focusGoalMinutes, 0);
    expect(settings.focusAutoBlockEnabled, isFalse);
    expect(settings.focusCutoffMinutes, 20 * 60);
    expect(settings.focusDate, isNull);
    expect(settings.focusSecondsToday, 0);
    expect(settings.focusSessionStartedAt, isNull);
    expect(settings.focusSessionEndsAt, isNull);
    expect(settings.focusSessionRemainingSeconds, 0);
    expect(settings.focusSessionLengthMinutes, 25);
  });

  test('round-trips every field', () async {
    final repository = await freshRepository();
    final studyEndsAt = DateTime(2026, 10, 29, 22, 30);
    final focusStart = DateTime(2026, 10, 29, 20);
    final focusEnd = DateTime(2026, 10, 29, 20, 30);
    final original = UsageSettings(
      dailyLimitSeconds: 5400,
      isLocked: true,
      lockedAt: DateTime(2026, 10, 29, 14, 5),
      nextResetAt: DateTime(2026, 10, 30),
      onboardingCompleted: true,
      overnightLockEnabled: true,
      studyEndsAt: studyEndsAt,
      studyLengthMinutes: 45,
      focusGoalMinutes: 120,
      focusAutoBlockEnabled: true,
      focusCutoffMinutes: 21 * 60 + 15,
      focusDate: '2026-10-29',
      focusSecondsToday: 1800,
      focusSessionStartedAt: focusStart,
      focusSessionEndsAt: focusEnd,
      focusSessionRemainingSeconds: 1200,
      focusSessionLengthMinutes: 45,
    );

    await repository.save(original);
    final loaded = await repository.load();

    expect(loaded.dailyLimitSeconds, 5400);
    expect(loaded.isLocked, isTrue);
    expect(loaded.lockedAt, DateTime(2026, 10, 29, 14, 5));
    expect(loaded.nextResetAt, DateTime(2026, 10, 30));
    expect(loaded.onboardingCompleted, isTrue);
    expect(loaded.overnightLockEnabled, isTrue);
    expect(loaded.studyEndsAt, studyEndsAt);
    expect(loaded.studyLengthMinutes, 45);
    expect(loaded.focusGoalMinutes, 120);
    expect(loaded.focusAutoBlockEnabled, isTrue);
    expect(loaded.focusCutoffMinutes, 21 * 60 + 15);
    expect(loaded.focusDate, '2026-10-29');
    expect(loaded.focusSecondsToday, 1800);
    expect(loaded.focusSessionStartedAt, focusStart);
    expect(loaded.focusSessionEndsAt, focusEnd);
    expect(loaded.focusSessionRemainingSeconds, 1200);
    expect(loaded.focusSessionLengthMinutes, 45);
  });

  test('clearing the focus session and date removes their keys', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = PrefsSettingsRepository(prefs);

    await repository.save(
      UsageSettings(
        dailyLimitSeconds: 0,
        isLocked: false,
        lockedAt: null,
        nextResetAt: DateTime(2026, 11, 1),
        onboardingCompleted: true,
        focusDate: '2026-10-31',
        focusSessionStartedAt: DateTime(2026, 10, 31, 20),
        focusSessionEndsAt: DateTime(2026, 10, 31, 20, 25),
        focusSessionRemainingSeconds: 1500,
      ),
    );
    await repository.save(
      UsageSettings(
        dailyLimitSeconds: 0,
        isLocked: false,
        lockedAt: null,
        nextResetAt: DateTime(2026, 11, 1),
        onboardingCompleted: true,
      ),
    );

    expect(
      prefs.getInt(PrefsSettingsRepository.keyFocusSessionStartedAt),
      isNull,
    );
    expect(prefs.getInt(PrefsSettingsRepository.keyFocusSessionEndsAt), isNull);
    expect(prefs.getString(PrefsSettingsRepository.keyFocusDate), isNull);
    final loaded = await repository.load();
    expect(loaded.focusSessionStartedAt, isNull);
    expect(loaded.focusSessionEndsAt, isNull);
    expect(loaded.focusDate, isNull);
    expect(loaded.focusSessionRemainingSeconds, 0);
  });

  test('clearing the study session removes its key', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = PrefsSettingsRepository(prefs);

    await repository.save(
      UsageSettings(
        dailyLimitSeconds: 1800,
        isLocked: false,
        lockedAt: null,
        nextResetAt: DateTime(2026, 11, 1),
        onboardingCompleted: true,
        studyEndsAt: DateTime(2026, 10, 31, 14),
        studyLengthMinutes: 25,
      ),
    );
    await repository.save(
      UsageSettings(
        dailyLimitSeconds: 1800,
        isLocked: false,
        lockedAt: null,
        nextResetAt: DateTime(2026, 11, 1),
        onboardingCompleted: true,
        studyLengthMinutes: 25,
      ),
    );

    expect(prefs.getInt(PrefsSettingsRepository.keyStudyEndsAt), isNull);
    final loaded = await repository.load();
    expect(loaded.studyEndsAt, isNull);
    expect(loaded.studyLengthMinutes, 25);
  });

  test('clearing lockedAt removes the stored key', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = PrefsSettingsRepository(prefs);
    await repository.save(
      UsageSettings(
        dailyLimitSeconds: 1800,
        isLocked: true,
        lockedAt: DateTime(2026, 10, 29, 14, 5),
        nextResetAt: DateTime(2026, 10, 30),
        onboardingCompleted: true,
      ),
    );

    await repository.save(
      UsageSettings(
        dailyLimitSeconds: 1800,
        isLocked: false,
        lockedAt: null,
        nextResetAt: DateTime(2026, 10, 30),
        onboardingCompleted: true,
      ),
    );

    expect(prefs.getInt(PrefsSettingsRepository.keyLockedAt), isNull);
    expect((await repository.load()).lockedAt, isNull);
  });

  test('round-trips the scheduled limit and effective date', () async {
    final repository = await freshRepository();
    final effectiveAt = DateTime(2026, 10, 31);

    await repository.save(
      UsageSettings(
        dailyLimitSeconds: 1800,
        isLocked: false,
        lockedAt: null,
        nextResetAt: DateTime(2026, 11, 1),
        onboardingCompleted: true,
        pendingLimitSeconds: 3600,
        pendingEffectiveAt: effectiveAt,
      ),
    );

    final loaded = await repository.load();
    expect(loaded.dailyLimitSeconds, 1800);
    expect(loaded.pendingLimitSeconds, 3600);
    expect(loaded.pendingEffectiveAt, effectiveAt);
  });

  test('clearing the scheduled limit removes its keys', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = PrefsSettingsRepository(prefs);

    await repository.save(
      UsageSettings(
        dailyLimitSeconds: 1800,
        isLocked: false,
        lockedAt: null,
        nextResetAt: DateTime(2026, 11, 1),
        onboardingCompleted: true,
        pendingLimitSeconds: 3600,
        pendingEffectiveAt: DateTime(2026, 10, 31),
      ),
    );

    await repository.save(
      UsageSettings(
        dailyLimitSeconds: 3600,
        isLocked: false,
        lockedAt: null,
        nextResetAt: DateTime(2026, 11, 1),
        onboardingCompleted: true,
      ),
    );

    expect(
      prefs.getInt(PrefsSettingsRepository.keyPendingLimitSeconds),
      isNull,
    );
    expect(prefs.getInt(PrefsSettingsRepository.keyPendingEffectiveAt), isNull);
    final loaded = await repository.load();
    expect(loaded.pendingLimitSeconds, isNull);
    expect(loaded.pendingEffectiveAt, isNull);
  });

  test('reload refreshes values written by the native layer', () async {
    SharedPreferences.setMockInitialValues({
      PrefsSettingsRepository.keyDailyLimitSeconds: 1800,
      PrefsSettingsRepository.keyIsLocked: false,
    });
    final prefs = await SharedPreferences.getInstance();
    final repository = PrefsSettingsRepository(prefs);
    expect((await repository.load()).isLocked, isFalse);

    // Simulate Kotlin writing the lock into the same prefs file, then Dart's
    // cache being refreshed when the app resumes.
    await prefs.setBool(PrefsSettingsRepository.keyIsLocked, true);
    await prefs.setInt(
      PrefsSettingsRepository.keyLockedAt,
      DateTime(2026, 10, 30, 14).millisecondsSinceEpoch,
    );
    await repository.reload();

    final loaded = await repository.load();
    expect(loaded.isLocked, isTrue);
    expect(loaded.lockedAt, DateTime(2026, 10, 30, 14));
  });
}
