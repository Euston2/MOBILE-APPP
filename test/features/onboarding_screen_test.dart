import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/entities/permission_snapshot.dart';

import '../helpers/fake_stores.dart';
import '../helpers/fakes.dart';
import '../helpers/pump_lockout.dart';

void main() {
  testWidgets('continue is disabled while usage access is missing', (
    tester,
  ) async {
    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(PermissionSnapshot.none),
      usage: FakeUsageRepository(),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(
      find.text('Allow app activity access so Lockout can count your time.'),
      findsOneWidget,
    );
  });

  testWidgets('opening settings routes to the matching permission', (
    tester,
  ) async {
    final permissions = FakePermissionsRepository(PermissionSnapshot.none);
    await pumpLockoutApp(
      tester,
      permissions: permissions,
      usage: FakeUsageRepository(),
    );

    await tester.tap(find.text('Open settings').first);
    await tester.pumpAndSettle();

    expect(permissions.openedSettings, [PermissionKind.usageAccess]);
  });

  testWidgets('continue works once usage access is granted', (tester) async {
    final permissions = FakePermissionsRepository(usageOnly);
    final settings = FakeSettingsRepository();
    await pumpLockoutApp(
      tester,
      permissions: permissions,
      usage: FakeUsageRepository(),
      settings: settings,
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
    expect(find.text('Continue with limited protection'), findsOneWidget);

    await tester.tap(find.text('Continue with limited protection'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsNWidgets(2));
    expect(settings.settings.onboardingCompleted, isTrue);

    await disposeTestApp(tester);
  });
}
