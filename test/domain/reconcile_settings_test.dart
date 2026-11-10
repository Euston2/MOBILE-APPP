import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/usecases/reconcile_settings.dart';

import '../helpers/fake_stores.dart';

void main() {
  final effectiveAt = DateTime(2026, 10, 30);
  final resetAt = DateTime(2026, 10, 31);

  test('applies a scheduled limit once its midnight has passed', () {
    final settings = settingsWith(
      dailyLimitSeconds: 1800,
      pendingLimitSeconds: 3600,
      pendingEffectiveAt: effectiveAt,
      nextResetAt: resetAt,
    );

    final before = reconcileSettings(
      settings,
      effectiveAt.subtract(const Duration(minutes: 1)),
    );
    expect(before.dailyLimitSeconds, 1800);
    expect(before.pendingLimitSeconds, 3600);

    final after = reconcileSettings(settings, effectiveAt);
    expect(after.dailyLimitSeconds, 3600);
    expect(after.pendingLimitSeconds, isNull);
    // Kept for the pending app-selection reconciler.
    expect(after.pendingEffectiveAt, effectiveAt);
  });

  test('keeps a lock before its reset instant', () {
    final settings = settingsWith(
      dailyLimitSeconds: 1800,
      isLocked: true,
      lockedAt: DateTime(2026, 10, 30, 14),
      nextResetAt: resetAt,
    );

    final result = reconcileSettings(settings, DateTime(2026, 10, 30, 23, 59));

    expect(result.isLocked, isTrue);
    expect(result.lockedAt, DateTime(2026, 10, 30, 14));
    expect(result.nextResetAt, resetAt);
  });

  test('clears a lock at or after the reset instant', () {
    final settings = settingsWith(
      dailyLimitSeconds: 1800,
      isLocked: true,
      lockedAt: DateTime(2026, 10, 30, 14),
      nextResetAt: resetAt,
    );

    final atReset = reconcileSettings(settings, resetAt);
    expect(atReset.isLocked, isFalse);
    expect(atReset.lockedAt, isNull);
    expect(atReset.nextResetAt, DateTime(2026, 11, 1));

    final afterReset = reconcileSettings(settings, DateTime(2026, 11, 2, 9));
    expect(afterReset.isLocked, isFalse);
    expect(afterReset.nextResetAt, DateTime(2026, 11, 3));
  });

  test('keeps the daily limit active on later days', () {
    final settings = settingsWith(
      dailyLimitSeconds: 1800,
      nextResetAt: resetAt,
    );

    final nextDay = reconcileSettings(settings, DateTime(2026, 10, 31, 9));
    expect(nextDay.dailyLimitSeconds, 1800);
    expect(nextDay.isLocked, isFalse);
    expect(nextDay.nextResetAt, DateTime(2026, 11, 1));

    final laterDay = reconcileSettings(nextDay, DateTime(2026, 11, 3, 18));
    expect(laterDay.dailyLimitSeconds, 1800);
    expect(laterDay.pendingLimitSeconds, isNull);
    expect(laterDay.nextResetAt, DateTime(2026, 11, 4));
  });

  test('keeps a scheduled limit after it becomes active', () {
    final settings = settingsWith(
      dailyLimitSeconds: 1800,
      pendingLimitSeconds: 3600,
      pendingEffectiveAt: effectiveAt,
      nextResetAt: resetAt,
    );

    final applied = reconcileSettings(settings, DateTime(2026, 10, 30, 0, 1));
    expect(applied.dailyLimitSeconds, 3600);
    expect(applied.pendingLimitSeconds, isNull);

    final nextDay = reconcileSettings(applied, DateTime(2026, 11, 1, 9));
    expect(nextDay.dailyLimitSeconds, 3600);
    expect(nextDay.pendingLimitSeconds, isNull);
  });

  test('rolls an expired reset forward even when no lock is active', () {
    final settings = settingsWith(
      dailyLimitSeconds: 1800,
      nextResetAt: resetAt,
    );

    final result = reconcileSettings(settings, DateTime(2026, 11, 2, 9));

    expect(result.nextResetAt, DateTime(2026, 11, 3));
    expect(result.lockedAt, isNull);
    expect(result.isLocked, isFalse);
  });

  test('clears a study session once its end instant is reached', () {
    final studyEnd = DateTime(2026, 10, 30, 15);
    final settings = settingsWith(
      dailyLimitSeconds: 1800,
      nextResetAt: resetAt,
      studyEndsAt: studyEnd,
      studyLengthMinutes: 45,
    );

    final before = reconcileSettings(
      settings,
      studyEnd.subtract(const Duration(seconds: 1)),
    );
    expect(before.studyEndsAt, studyEnd);
    expect(before.studyLengthMinutes, 45);

    final atEnd = reconcileSettings(settings, studyEnd);
    expect(atEnd.studyEndsAt, isNull);
    // The last duration stays selected for the next session.
    expect(atEnd.studyLengthMinutes, 45);
  });

  test('banks a finished focus session into today’s total', () {
    final startedAt = DateTime(2026, 10, 30, 9);
    final endedAt = DateTime(2026, 10, 30, 9, 25);
    final settings = settingsWith(
      focusDate: '2026-10-30',
      focusSecondsToday: 600,
      focusSessionStartedAt: startedAt,
      focusSessionEndsAt: endedAt,
      focusSessionRemainingSeconds: 1500,
      nextResetAt: resetAt,
    );

    final before = reconcileSettings(
      settings,
      endedAt.subtract(const Duration(seconds: 1)),
    );
    expect(before.focusSessionEndsAt, endedAt);
    expect(before.focusSecondsToday, 600);

    final atEnd = reconcileSettings(settings, endedAt);
    expect(atEnd.focusSessionStartedAt, isNull);
    expect(atEnd.focusSessionEndsAt, isNull);
    expect(atEnd.focusSessionRemainingSeconds, 0);
    expect(atEnd.focusDate, '2026-10-30');
    expect(atEnd.focusSecondsToday, 600 + 25 * 60);
  });

  test('banks only the current day portion of a cross-midnight session', () {
    final settings = settingsWith(
      focusDate: '2026-10-30',
      focusSessionStartedAt: DateTime(2026, 10, 30, 23, 50),
      focusSessionEndsAt: DateTime(2026, 10, 31, 0, 20),
      focusSessionRemainingSeconds: 1800,
      nextResetAt: resetAt,
    );

    final result = reconcileSettings(settings, DateTime(2026, 10, 31, 0, 21));

    expect(result.focusDate, '2026-10-31');
    expect(result.focusSecondsToday, 20 * 60);
    expect(result.focusSessionEndsAt, isNull);
  });

  test('keeps the overnight toggle across reconciliations', () {
    final settings = settingsWith(
      overnightLockEnabled: true,
      nextResetAt: resetAt,
    );

    final result = reconcileSettings(settings, DateTime(2026, 10, 31, 9));

    expect(result.overnightLockEnabled, isTrue);
  });

  test('does nothing when neither transition is due', () {
    final settings = settingsWith(
      dailyLimitSeconds: 1800,
      nextResetAt: resetAt,
    );

    expect(reconcileSettings(settings, DateTime(2026, 10, 30, 12)), settings);
  });
}
