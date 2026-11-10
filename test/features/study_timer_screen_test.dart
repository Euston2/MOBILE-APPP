import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/di.dart';
import 'package:lockout/core/utils/day_window.dart';
import 'package:lockout/domain/entities/monitored_app.dart';
import 'package:lockout/features/focus/presentation/study_timer_screen.dart';

import '../helpers/fake_stores.dart';
import '../helpers/test_surface.dart';

void main() {
  const instagram = MonitoredApp(
    packageName: 'com.instagram.android',
    displayName: 'Instagram',
  );

  Future<void> pumpTimer(
    WidgetTester tester, {
    required FakeSettingsRepository settings,
  }) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settings),
          monitoredAppsRepositoryProvider.overrideWithValue(
            FakeMonitoredAppsRepository(const [instagram]),
          ),
        ],
        child: const MaterialApp(home: StudyTimerScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('starts, pauses and resumes a cumulative focus session', (
    tester,
  ) async {
    final settings = FakeSettingsRepository(
      initial: settingsWith(
        focusDate: localDateKey(DateTime.now()),
        focusSecondsToday: 300,
      ),
    );
    await pumpTimer(tester, settings: settings);

    expect(find.text('Study timer'), findsOneWidget);
    expect(find.text('5m'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);

    await tester.tap(find.text('Start focus'));
    await tester.pump();
    await tester.pump();

    expect(settings.settings.focusSessionStartedAt, isNotNull);
    expect(find.text('Focusing'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump();
    await tester.pump();

    expect(settings.settings.focusSessionStartedAt, isNull);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pump();
    await tester.pump();

    expect(settings.settings.focusSessionStartedAt, isNotNull);
    expect(find.text('Focusing'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows the missed-goal block and keeps the timer available', (
    tester,
  ) async {
    final settings = FakeSettingsRepository(
      initial: settingsWith(
        focusGoalMinutes: 60,
        focusAutoBlockEnabled: true,
        focusCutoffMinutes: 0,
        focusDate: localDateKey(DateTime.now()),
      ),
    );
    await pumpTimer(tester, settings: settings);

    expect(find.textContaining('blocked until midnight'), findsOneWidget);
    expect(find.text('Edit goal'), findsOneWidget);

    final goalButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Edit goal'),
    );
    expect(goalButton.onPressed, isNull);
    final automation = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Block if I miss my goal'),
    );
    expect(automation.onChanged, isNull);
    final cutoff = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Start blocking at'),
    );
    expect(cutoff.onTap, isNull);

    // Starting a timer is the documented way to clear the block early.
    await tester.tap(find.text('Start focus'));
    await tester.pump();
    await tester.pump();

    expect(settings.settings.focusSessionStartedAt, isNotNull);
    expect(find.text('Focusing'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
