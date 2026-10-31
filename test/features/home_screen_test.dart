import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/entities/installed_app.dart';
import 'package:lockout/domain/entities/monitored_app.dart';

import '../helpers/fake_stores.dart';
import '../helpers/fakes.dart';
import '../helpers/pump_lockout.dart';

void main() {
  testWidgets('lists per-app usage with friendly labels', (tester) async {
    final usage = FakeUsageRepository(
      summary: summaryOf([
        (packageName: 'com.zhiliaoapp.musically', seconds: 1800),
        (packageName: 'com.instagram.android', seconds: 600),
      ]),
      apps: const [
        InstalledApp(
          packageName: 'com.zhiliaoapp.musically',
          displayName: 'TikTok',
        ),
        InstalledApp(
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
        ),
      ],
    );

    await pumpLockoutApp(
      tester,
      usage: usage,
      permissions: FakePermissionsRepository(allGranted),
    );

    expect(find.text('TikTok'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('30m'), findsOneWidget);
    expect(find.text('10m'), findsOneWidget);
    expect(find.text('40m'), findsOneWidget);
    expect(find.text('Since 00:00 · 2 apps'), findsOneWidget);
    expect(find.text('No daily limit set yet'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('falls back to the package name when the label is unknown', (
    tester,
  ) async {
    final usage = FakeUsageRepository(
      summary: summaryOf([(packageName: 'com.example.unknown', seconds: 120)]),
      apps: const [],
    );

    await pumpLockoutApp(
      tester,
      usage: usage,
      permissions: FakePermissionsRepository(allGranted),
    );

    expect(find.text('com.example.unknown'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('shows an error with retry when usage cannot be read', (
    tester,
  ) async {
    final usage = FakeUsageRepository(error: StateError('usage unavailable'));

    await pumpLockoutApp(
      tester,
      usage: usage,
      permissions: FakePermissionsRepository(allGranted),
    );

    expect(find.text("Couldn't reach the Android layer"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('shows the empty state when nothing was used today', (
    tester,
  ) async {
    await pumpLockoutApp(
      tester,
      usage: FakeUsageRepository(),
      permissions: FakePermissionsRepository(allGranted),
    );

    expect(find.textContaining('No usage recorded yet today'), findsOneWidget);
    expect(find.text('0m'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('ring compares usage with the saved limit', (tester) async {
    await pumpLockoutApp(
      tester,
      usage: FakeUsageRepository(
        summary: summaryOf([
          (packageName: 'com.instagram.android', seconds: 3900),
        ]),
      ),
      permissions: FakePermissionsRepository(allGranted),
      settings: FakeSettingsRepository(
        initial: settingsWith(dailyLimitSeconds: 3600),
      ),
      monitored: FakeMonitoredAppsRepository(const [
        MonitoredApp(
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
        ),
      ]),
    );

    expect(find.text('1h 05m'), findsWidgets);
    expect(find.text('of 1h'), findsOneWidget);
    expect(find.text('Limit reached · 5m over'), findsOneWidget);
    expect(find.text('1 monitored'), findsOneWidget);
    expect(find.text('Edit limit & apps'), findsOneWidget);
    expect(
      find.text('Monitored apps are blocked until 00:00.'),
      findsOneWidget,
    );

    await disposeTestApp(tester);
  });

  testWidgets('shows the remaining time while under the limit', (tester) async {
    await pumpLockoutApp(
      tester,
      usage: FakeUsageRepository(
        summary: summaryOf([
          (packageName: 'com.instagram.android', seconds: 900),
        ]),
      ),
      permissions: FakePermissionsRepository(allGranted),
      settings: FakeSettingsRepository(
        initial: settingsWith(dailyLimitSeconds: 3600),
      ),
      monitored: FakeMonitoredAppsRepository(const [
        MonitoredApp(
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
        ),
      ]),
    );

    expect(find.text('of 1h'), findsOneWidget);
    expect(find.text('45m left today'), findsOneWidget);
    expect(find.text('Monitored apps are blocked until 00:00.'), findsNothing);

    await disposeTestApp(tester);
  });

  testWidgets('shows the lock state instead of the remaining time', (
    tester,
  ) async {
    await pumpLockoutApp(
      tester,
      usage: FakeUsageRepository(
        summary: summaryOf([
          (packageName: 'com.instagram.android', seconds: 3900),
        ]),
      ),
      permissions: FakePermissionsRepository(allGranted),
      settings: FakeSettingsRepository(
        initial: settingsWith(
          dailyLimitSeconds: 3600,
          isLocked: true,
          lockedAt: DateTime.now(),
          nextResetAt: DateTime.now().add(const Duration(hours: 8)),
        ),
      ),
      monitored: FakeMonitoredAppsRepository(const [
        MonitoredApp(
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
        ),
      ]),
    );

    expect(find.text('Locked until 00:00'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('Edit limit & apps'), findsNothing);
    expect(
      find.text('Monitored apps are blocked until 00:00.'),
      findsOneWidget,
    );

    await disposeTestApp(tester);
  });

  testWidgets('announces settings scheduled for midnight', (tester) async {
    await pumpLockoutApp(
      tester,
      usage: FakeUsageRepository(
        summary: summaryOf([
          (packageName: 'com.instagram.android', seconds: 900),
        ]),
      ),
      permissions: FakePermissionsRepository(allGranted),
      settings: FakeSettingsRepository(
        initial: settingsWith(
          dailyLimitSeconds: 1800,
          pendingLimitSeconds: 3600,
          pendingEffectiveAt: DateTime.now().add(const Duration(hours: 8)),
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
    );

    expect(find.text('New settings start at 00:00'), findsOneWidget);
    expect(find.textContaining('Tomorrow: 1h · 2 apps'), findsOneWidget);
    // Today's limit is still the active one.
    expect(find.text('15m left today'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('shows a retry banner when the native blocker fails', (
    tester,
  ) async {
    await pumpLockoutApp(
      tester,
      usage: FakeUsageRepository(),
      permissions: FakePermissionsRepository(allGranted),
      settings: FakeSettingsRepository(
        initial: settingsWith(dailyLimitSeconds: 1800),
      ),
      monitored: FakeMonitoredAppsRepository(const [
        MonitoredApp(
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
        ),
      ]),
      blocking: FakeBlockingRepository(error: StateError('service refused')),
    );

    expect(find.text("The blocker couldn't start"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await disposeTestApp(tester);
  });
}
