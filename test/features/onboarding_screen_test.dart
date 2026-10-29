import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/app.dart';
import 'package:lockout/core/di.dart';
import 'package:lockout/domain/entities/permission_snapshot.dart';

import '../helpers/fakes.dart';
import '../helpers/test_surface.dart';

void main() {
  Future<void> pumpOnboarding(
    WidgetTester tester, {
    required FakePermissionsRepository permissions,
  }) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsRepositoryProvider.overrideWithValue(permissions),
          usageRepositoryProvider.overrideWithValue(FakeUsageRepository()),
        ],
        child: const LockoutApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('continue is disabled while usage access is missing', (
    tester,
  ) async {
    await pumpOnboarding(
      tester,
      permissions: FakePermissionsRepository(PermissionSnapshot.none),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(
      find.text('Usage access is required before anything can be counted.'),
      findsOneWidget,
    );
  });

  testWidgets('opening settings routes to the matching permission', (
    tester,
  ) async {
    final permissions = FakePermissionsRepository(PermissionSnapshot.none);
    await pumpOnboarding(tester, permissions: permissions);

    await tester.tap(find.text('Open settings').first);
    await tester.pumpAndSettle();

    expect(permissions.openedSettings, [PermissionKind.usageAccess]);
  });

  testWidgets('continue works once usage access is granted', (tester) async {
    final permissions = FakePermissionsRepository(
      const PermissionSnapshot(
        usageAccess: true,
        overlay: false,
        notifications: false,
        batteryOptimizationIgnored: false,
      ),
    );
    await pumpOnboarding(tester, permissions: permissions);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
    expect(find.text('Continue with limited protection'), findsOneWidget);

    await tester.tap(find.text('Continue with limited protection'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
