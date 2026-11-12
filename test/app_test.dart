import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/utils/day_window.dart';
import 'package:lockout/domain/entities/monitored_app.dart';
import 'package:lockout/domain/entities/permission_snapshot.dart';
import 'package:lockout/features/shell/presentation/main_shell.dart';
import 'package:lockout/features/shell/presentation/reader_launch_controller.dart';

import 'helpers/fake_reader.dart';
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
    expect(find.text('App activity access'), findsOneWidget);
    expect(find.text('Show over other apps'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Battery saver'), findsOneWidget);
    expect(find.text('0 of 4 ready'), findsOneWidget);
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

    expect(find.text('Today'), findsNWidgets(2));
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

    expect(find.text('Today'), findsNWidgets(2));
    expect(find.text('4 settings need attention'), findsOneWidget);
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

    expect(find.text('Today'), findsNWidgets(2));
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

  testWidgets('keeps a saved limit active after its reset date has passed', (
    tester,
  ) async {
    final blocking = FakeBlockingRepository();
    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      settings: FakeSettingsRepository(
        initial: settingsWith(
          dailyLimitSeconds: 3600,
          nextResetAt: DateTime.now().subtract(const Duration(days: 2)),
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
    expect(config.dailyLimitSeconds, 3600);
    expect(config.monitoredPackages, {'com.instagram.android'});
    expect(config.isActive, isTrue);
    expect(config.nextResetAt.isAfter(DateTime.now()), isTrue);

    await disposeTestApp(tester);
  });

  testWidgets('refreshing Home re-sends the saved limit to the watcher', (
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

    final before = blocking.synced.length;
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();

    expect(blocking.synced.length, greaterThan(before));
    expect(blocking.synced.last.dailyLimitSeconds, 3600);
    expect(blocking.synced.last.isActive, isTrue);

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

  testWidgets('pushes focus locks to the native watcher', (tester) async {
    final blocking = FakeBlockingRepository();
    final studyEndsAt = DateTime.now().add(const Duration(minutes: 45));
    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      settings: FakeSettingsRepository(
        initial: settingsWith(
          overnightLockEnabled: true,
          studyEndsAt: studyEndsAt,
          studyLengthMinutes: 45,
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
    expect(config.overnightLockEnabled, isTrue);
    expect(config.studyEndsAt, studyEndsAt);
    expect(config.hasOvernightFocus, isTrue);
    expect(config.hasStudyFocus, isTrue);
    expect(config.isActive, isTrue);

    await disposeTestApp(tester);
  });

  testWidgets('starts the watcher for a focus lock without a daily limit', (
    tester,
  ) async {
    final blocking = FakeBlockingRepository();
    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      settings: FakeSettingsRepository(
        initial: settingsWith(
          studyEndsAt: DateTime.now().add(const Duration(minutes: 25)),
          studyLengthMinutes: 25,
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

    expect(blocking.synced, isNotEmpty);
    expect(blocking.synced.last.studyEndsAt, isNotNull);
    expect(blocking.synced.last.isActive, isTrue);

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

  testWidgets('opens the Reader from bottom navigation and its settings', (
    tester,
  ) async {
    final reader = FakeReaderRepository();
    reader.articles['cached'] = readerArticle(
      id: 'cached',
      title: 'Already here',
      sourceName: 'Example Review',
    );
    reader.dailyPicks[localDateKey(DateTime.now())] = ['cached'];

    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      reader: reader,
    );

    // Reader is built lazily, so its app-bar action is absent until opened.
    expect(find.byTooltip('Reader settings'), findsNothing);

    await tester.tap(find.text('Reader'));
    await tester.pumpAndSettle();

    expect(find.text('Already here'), findsOneWidget);
    expect(find.byTooltip('Reader settings'), findsOneWidget);

    await tester.tap(find.byTooltip('Reader settings'));
    await tester.pumpAndSettle();
    expect(find.text('Sources & topics'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('opens the Reader when the block screen requests it', (
    tester,
  ) async {
    final reader = FakeReaderRepository();
    reader.articles['cached'] = readerArticle(
      id: 'cached',
      title: 'Read this instead',
      sourceName: 'Example Review',
    );
    reader.dailyPicks[localDateKey(DateTime.now())] = ['cached'];

    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      reader: reader,
    );

    // A normal launch stays on Today.
    expect(find.text('Reader settings'), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MainShell)),
    );
    container.read(readerLaunchProvider.notifier).open();
    await tester.pumpAndSettle();

    expect(find.text('Read this instead'), findsOneWidget);
    expect(find.byTooltip('Reader settings'), findsOneWidget);

    await disposeTestApp(tester);
  });
}
