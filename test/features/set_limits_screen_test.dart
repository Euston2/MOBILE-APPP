import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/di.dart';
import 'package:lockout/domain/entities/installed_app.dart';
import 'package:lockout/domain/entities/monitored_app.dart';
import 'package:lockout/features/limits/presentation/set_limits_screen.dart';

import '../helpers/fake_stores.dart';
import '../helpers/fakes.dart';
import '../helpers/test_surface.dart';

void main() {
  Future<void> pumpLimits(
    WidgetTester tester, {
    required FakeSettingsRepository settings,
    required FakeMonitoredAppsRepository monitored,
    FakeUsageRepository? usage,
  }) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settings),
          monitoredAppsRepositoryProvider.overrideWithValue(monitored),
          usageRepositoryProvider.overrideWithValue(
            usage ??
                FakeUsageRepository(
                  apps: const [
                    InstalledApp(
                      packageName: 'com.instagram.android',
                      displayName: 'Instagram',
                    ),
                    InstalledApp(
                      packageName: 'com.zhiliaoapp.musically',
                      displayName: 'TikTok',
                    ),
                  ],
                ),
          ),
        ],
        child: const MaterialApp(home: _Host()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open limits'));
    await tester.pumpAndSettle();
  }

  testWidgets('preloads the saved limit and selection', (tester) async {
    await pumpLimits(
      tester,
      settings: FakeSettingsRepository(
        initial: settingsWith(dailyLimitSeconds: 1800),
      ),
      monitored: FakeMonitoredAppsRepository(const [
        MonitoredApp(
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
        ),
      ]),
    );

    expect(find.text('30m'), findsWidgets);
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('combined across 1 app'), findsOneWidget);
  });

  testWidgets('schedules a new limit and selection for tomorrow', (
    tester,
  ) async {
    final settings = FakeSettingsRepository(
      initial: settingsWith(dailyLimitSeconds: 1800),
    );
    final monitored = FakeMonitoredAppsRepository(const [
      MonitoredApp(
        packageName: 'com.instagram.android',
        displayName: 'Instagram',
      ),
    ]);

    await pumpLimits(tester, settings: settings, monitored: monitored);

    await tester.tap(find.text('45m'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(CheckboxListTile, 'TikTok'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save for tomorrow'));
    await tester.pumpAndSettle();

    // Today's limit is untouched; the new one waits for midnight.
    expect(settings.settings.dailyLimitSeconds, 1800);
    expect(settings.settings.pendingLimitSeconds, 2700);
    expect(settings.settings.pendingEffectiveAt, isNotNull);

    final byPackage = {for (final app in monitored.apps) app.packageName: app};
    expect(byPackage['com.instagram.android']?.isEnabled, isTrue);
    expect(byPackage['com.instagram.android']?.pendingEnabled, isNull);
    expect(byPackage['com.zhiliaoapp.musically']?.isEnabled, isFalse);
    expect(byPackage['com.zhiliaoapp.musically']?.pendingEnabled, isTrue);

    expect(find.text('Saved. Starts tomorrow at 00:00.'), findsOneWidget);
  });

  testWidgets('first setup applies immediately', (tester) async {
    final settings = FakeSettingsRepository();
    final monitored = FakeMonitoredAppsRepository();

    await pumpLimits(tester, settings: settings, monitored: monitored);

    await tester.tap(find.text('45m'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'TikTok'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(settings.settings.dailyLimitSeconds, 2700);
    expect(settings.settings.pendingLimitSeconds, isNull);
    expect(monitored.apps, hasLength(1));
    expect(monitored.apps.single.packageName, 'com.zhiliaoapp.musically');
    expect(monitored.apps.single.isEnabled, isTrue);
    expect(monitored.apps.single.pendingEnabled, isNull);
    expect(find.text('Limit and apps saved'), findsOneWidget);
  });

  testWidgets('preloads scheduled values and explains what applies today', (
    tester,
  ) async {
    await pumpLimits(
      tester,
      settings: FakeSettingsRepository(
        initial: settingsWith(
          dailyLimitSeconds: 1800,
          pendingLimitSeconds: 2700,
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

    expect(find.text('45m'), findsWidgets);
    expect(find.text('2 selected'), findsOneWidget);
    expect(find.textContaining('These changes start tomorrow'), findsOneWidget);
    expect(
      find.textContaining('Today\'s limit is 30m · 1 app'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Save for tomorrow'),
      findsOneWidget,
    );
  });

  testWidgets('a selection without an active limit applies immediately', (
    tester,
  ) async {
    final settings = FakeSettingsRepository();
    final monitored = FakeMonitoredAppsRepository(const [
      MonitoredApp(
        packageName: 'com.instagram.android',
        displayName: 'Instagram',
      ),
    ]);

    await pumpLimits(tester, settings: settings, monitored: monitored);

    await tester.tap(find.text('45m'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(settings.settings.dailyLimitSeconds, 2700);
    expect(settings.settings.pendingLimitSeconds, isNull);
    expect(monitored.apps.single.isEnabled, isTrue);
    expect(monitored.apps.single.pendingEnabled, isNull);
  });

  testWidgets('cannot save without at least one app', (tester) async {
    await pumpLimits(
      tester,
      settings: FakeSettingsRepository(),
      monitored: FakeMonitoredAppsRepository(),
    );

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Select at least one app'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('is read-only while the lock is active', (tester) async {
    await pumpLimits(
      tester,
      settings: FakeSettingsRepository(
        initial: settingsWith(
          dailyLimitSeconds: 1800,
          isLocked: true,
          lockedAt: DateTime.now(),
        ),
      ),
      monitored: FakeMonitoredAppsRepository(const [
        MonitoredApp(
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
        ),
      ]),
    );

    expect(find.textContaining('Locked until 00:00'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);

    final tile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'TikTok'),
    );
    expect(tile.onChanged, isNull);
  });
}

/// Hosts SetLimitsScreen on a pushed route so saving can pop back to a parent.
class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SetLimitsScreen()),
          ),
          child: const Text('Open limits'),
        ),
      ),
    );
  }
}
