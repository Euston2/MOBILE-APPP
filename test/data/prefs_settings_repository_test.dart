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
  });

  test('round-trips every field', () async {
    final repository = await freshRepository();
    final original = UsageSettings(
      dailyLimitSeconds: 5400,
      isLocked: true,
      lockedAt: DateTime(2026, 10, 29, 14, 5),
      nextResetAt: DateTime(2026, 10, 30),
      onboardingCompleted: true,
    );

    await repository.save(original);
    final loaded = await repository.load();

    expect(loaded.dailyLimitSeconds, 5400);
    expect(loaded.isLocked, isTrue);
    expect(loaded.lockedAt, DateTime(2026, 10, 29, 14, 5));
    expect(loaded.nextResetAt, DateTime(2026, 10, 30));
    expect(loaded.onboardingCompleted, isTrue);
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
}
