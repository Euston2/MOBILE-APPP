import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/entities/device_diagnostics.dart';

import '../helpers/fake_stores.dart';
import '../helpers/fakes.dart';
import '../helpers/pump_lockout.dart';

DeviceDiagnostics _diagnostics() => DeviceDiagnostics(
  manufacturer: 'Xiaomi',
  brand: 'Redmi',
  model: 'Note 12',
  sdkInt: 33,
  usageAccess: true,
  overlay: true,
  notifications: true,
  batteryOptimizationIgnored: false,
  exactAlarmsAllowed: false,
  serviceConfigured: true,
  limitSeconds: 3600,
  monitoredCount: 2,
  lastArchivedDate: '2026-10-31',
  events: [
    DiagnosticEvent(
      at: DateTime(2026, 10, 31, 12, 3, 4),
      level: 'INFO',
      message: 'service started: 2 apps, 3600s limit',
    ),
  ],
);

void main() {
  testWidgets('shows OEM guidance, checks and recent events', (tester) async {
    final diagnostics = FakeDiagnosticsRepository(diagnostics: _diagnostics());

    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      diagnostics: diagnostics,
    );

    expect(find.text('Protection check'), findsOneWidget);
    await tester.tap(find.text('Protection check'));
    await tester.pumpAndSettle();

    expect(find.text('Protection needs work'), findsOneWidget);
    expect(find.text('3 of 4 essential checks passed'), findsOneWidget);
    expect(
      find.textContaining('Keep Lockout running on Xiaomi / Redmi / POCO'),
      findsOneWidget,
    );
    expect(find.text('Open autostart settings'), findsOneWidget);
    expect(find.text('Open battery settings'), findsOneWidget);
    expect(find.text('service started: 2 apps, 3600s limit'), findsOneWidget);
    expect(diagnostics.loadCalls, greaterThanOrEqualTo(1));

    await tester.tap(find.text('Open autostart settings'));
    await tester.pump();
    expect(diagnostics.autostartCalls, 1);

    final batteryTile = find.widgetWithText(ListTile, 'Battery optimisation');
    await tester.tap(
      find.descendant(of: batteryTile, matching: find.text('Open')),
    );
    await tester.pump();

    final exactTile = find.widgetWithText(ListTile, 'Exact alarms');
    await tester.tap(
      find.descendant(of: exactTile, matching: find.text('Open')),
    );
    await tester.pump();
    expect(diagnostics.exactAlarmCalls, 1);

    await disposeTestApp(tester);
  });

  testWidgets('copies the diagnostics report', (tester) async {
    final diagnostics = FakeDiagnosticsRepository(diagnostics: _diagnostics());
    String? copied;

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      diagnostics: diagnostics,
    );
    await tester.tap(find.text('Protection check'));
    await tester.pumpAndSettle();

    final copyButton = find.text('Copy diagnostics');
    await tester.ensureVisible(copyButton);
    await tester.tap(copyButton);
    await tester.pump();

    expect(copied, isNotNull);
    expect(copied, contains('Lockout diagnostics'));
    expect(copied, contains('Device: Xiaomi Note 12 (Android SDK 33)'));
    expect(copied, contains('service started: 2 apps, 3600s limit'));
    expect(find.text('Diagnostics copied to the clipboard.'), findsOneWidget);

    await disposeTestApp(tester);
  });
}
