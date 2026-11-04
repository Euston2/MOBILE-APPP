import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/di.dart';
import 'package:lockout/domain/entities/monitored_app.dart';
import 'package:lockout/features/focus/presentation/focus_screen.dart';

import '../helpers/fake_stores.dart';
import '../helpers/test_surface.dart';

void main() {
  const instagram = MonitoredApp(
    packageName: 'com.instagram.android',
    displayName: 'Instagram',
  );

  Future<void> pumpFocus(
    WidgetTester tester, {
    required FakeSettingsRepository settings,
    required FakeMonitoredAppsRepository monitored,
  }) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settings),
          monitoredAppsRepositoryProvider.overrideWithValue(monitored),
        ],
        child: const MaterialApp(home: FocusScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('requires a selected app before a focus lock can start', (
    tester,
  ) async {
    await pumpFocus(
      tester,
      settings: FakeSettingsRepository(),
      monitored: FakeMonitoredAppsRepository(),
    );

    expect(find.text('No apps selected yet'), findsOneWidget);
    expect(
      find.text('Choose at least one app before turning on a focus lock.'),
      findsOneWidget,
    );

    final overnight = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Block every night'),
    );
    final study = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Start study lock'),
    );
    expect(overnight.onChanged, isNull);
    expect(study.onChanged, isNull);
  });

  testWidgets('turns on the recurring overnight lock', (tester) async {
    final settings = FakeSettingsRepository();
    await pumpFocus(
      tester,
      settings: settings,
      monitored: FakeMonitoredAppsRepository(const [instagram]),
    );

    await tester.tap(find.widgetWithText(SwitchListTile, 'Block every night'));
    await tester.pumpAndSettle();

    expect(settings.settings.overnightLockEnabled, isTrue);
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Block every night'),
          )
          .value,
      isTrue,
    );
  });

  testWidgets('starts a study session and locks the controls', (tester) async {
    final settings = FakeSettingsRepository();
    await pumpFocus(
      tester,
      settings: settings,
      monitored: FakeMonitoredAppsRepository(const [instagram]),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, '45m'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Start study lock'));
    await tester.pumpAndSettle();

    expect(settings.settings.studyEndsAt, isNotNull);
    expect(settings.settings.studyLengthMinutes, 45);
    expect(find.text('Study lock is on'), findsOneWidget);
    expect(find.textContaining('Ends at'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);

    final study = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Study lock is on'),
    );
    expect(study.value, isTrue);
    expect(study.onChanged, isNull);
  });

  testWidgets('shows a running study session without a stop action', (
    tester,
  ) async {
    final endsAt = DateTime.now().add(const Duration(minutes: 20));
    await pumpFocus(
      tester,
      settings: FakeSettingsRepository(
        initial: settingsWith(studyEndsAt: endsAt, studyLengthMinutes: 25),
      ),
      monitored: FakeMonitoredAppsRepository(const [instagram]),
    );

    expect(find.text('Study lock is on'), findsOneWidget);
    expect(find.textContaining('You cannot turn it off'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);

    final study = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Study lock is on'),
    );
    expect(study.onChanged, isNull);
  });
}
