import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/entities/monitored_app.dart';
import 'package:lockout/domain/entities/permission_snapshot.dart';

import 'helpers/fake_stores.dart';
import 'helpers/fakes.dart';
import 'helpers/pump_lockout.dart';

void main() {
  testWidgets('shows onboarding when permissions are missing', (tester) async {
    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(PermissionSnapshot.none),
      usage: FakeUsageRepository(),
    );

    expect(find.text('Set up Lockout'), findsOneWidget);
    expect(find.text('Usage access'), findsOneWidget);
    expect(find.text('Display over other apps'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Battery optimisation'), findsOneWidget);
    expect(find.text('0 of 4 granted'), findsOneWidget);
  });

  testWidgets('shows Home when every permission is granted', (tester) async {
    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(
        summary: summaryOf([
          (packageName: 'com.instagram.android', seconds: 3900),
        ]),
      ),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('1h 05m'), findsWidgets);
    expect(find.text('No daily limit set yet'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('skipping onboarding persists the flag and lands on Home', (
    tester,
  ) async {
    final settings = FakeSettingsRepository();
    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(PermissionSnapshot.none),
      usage: FakeUsageRepository(),
      settings: settings,
    );

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('4 permissions missing'), findsOneWidget);
    expect(settings.settings.onboardingCompleted, isTrue);
    expect(settings.saveCalls, 1);

    await disposeTestApp(tester);
  });

  testWidgets('a completed setup goes straight to Home on next launch', (
    tester,
  ) async {
    final settings = FakeSettingsRepository(
      initial: settingsWith(onboardingCompleted: true),
    );
    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(PermissionSnapshot.none),
      usage: FakeUsageRepository(),
      settings: settings,
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Set up Lockout'), findsNothing);

    await disposeTestApp(tester);
  });

  testWidgets('pushes the limit and app selection to the native watcher', (
    tester,
  ) async {
    final blocking = FakeBlockingRepository();
    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      settings: FakeSettingsRepository(
        initial: settingsWith(dailyLimitSeconds: 3600),
      ),
      monitored: FakeMonitoredAppsRepository(const [
        MonitoredApp(
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
        ),
      ]),
      blocking: blocking,
    );

    expect(blocking.synced, isNotEmpty);
    final config = blocking.synced.last;
    expect(config.dailyLimitSeconds, 3600);
    expect(config.monitoredPackages, {'com.instagram.android'});
    expect(config.isLocked, isFalse);
    expect(config.isActive, isTrue);

    await disposeTestApp(tester);
  });

  testWidgets('pushes scheduled settings to the native watcher', (
    tester,
  ) async {
    final blocking = FakeBlockingRepository();
    final effectiveAt = DateTime.now().add(const Duration(hours: 8));
    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      settings: FakeSettingsRepository(
        initial: settingsWith(
          dailyLimitSeconds: 1800,
          pendingLimitSeconds: 3600,
          pendingEffectiveAt: effectiveAt,
        ),
      ),
      monitored: FakeMonitoredAppsRepository(const [
        MonitoredApp(
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
        ),
        MonitoredApp(
          packageName: 'com.zhiliaoapp.musically',
          displayName: 'TikTok',
          isEnabled: false,
          pendingEnabled: true,
        ),
      ]),
      blocking: blocking,
    );

    final config = blocking.synced.last;
    expect(config.dailyLimitSeconds, 1800);
    expect(config.monitoredPackages, {'com.instagram.android'});
    expect(config.pendingLimitSeconds, 3600);
    expect(config.pendingPackages, {
      'com.instagram.android',
      'com.zhiliaoapp.musically',
    });
    expect(config.pendingEffectiveAt, effectiveAt);

    await disposeTestApp(tester);
  });

  testWidgets('pushes the persisted lock to the native watcher', (
    tester,
  ) async {
    final blocking = FakeBlockingRepository();
    final resetAt = DateTime.now().add(const Duration(hours: 8));
    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      settings: FakeSettingsRepository(
        initial: settingsWith(
          dailyLimitSeconds: 3600,
          isLocked: true,
          lockedAt: DateTime.now(),
          nextResetAt: resetAt,
        ),
      ),
      monitored: FakeMonitoredAppsRepository(const [
        MonitoredApp(
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
        ),
      ]),
      blocking: blocking,
    );

    final config = blocking.synced.last;
    expect(config.isLocked, isTrue);
    expect(config.lockedAt, isNotNull);
    expect(config.nextResetAt, resetAt);

    await disposeTestApp(tester);
  });

  testWidgets('stops the native watcher when no limit is configured', (
    tester,
  ) async {
    final blocking = FakeBlockingRepository();
    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      blocking: blocking,
    );

    expect(blocking.synced, isEmpty);
    // The gate may recompute while settings and apps load; stop is idempotent.
    expect(blocking.stopCalls, greaterThanOrEqualTo(1));

    await disposeTestApp(tester);
  });
}
