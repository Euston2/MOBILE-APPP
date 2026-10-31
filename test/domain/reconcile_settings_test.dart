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

  test('does nothing when neither transition is due', () {
    final settings = settingsWith(
      dailyLimitSeconds: 1800,
      nextResetAt: resetAt,
    );

    expect(reconcileSettings(settings, DateTime(2026, 10, 30, 12)), settings);
  });
}
