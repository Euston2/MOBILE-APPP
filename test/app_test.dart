import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/app.dart';
import 'package:lockout/core/di.dart';
import 'package:lockout/domain/entities/permission_snapshot.dart';

import 'helpers/fakes.dart';
import 'helpers/test_surface.dart';

void main() {
  testWidgets('shows onboarding when permissions are missing', (tester) async {
    useTallScreen(tester);
    final permissions = FakePermissionsRepository(PermissionSnapshot.none);
    final usage = FakeUsageRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsRepositoryProvider.overrideWithValue(permissions),
          usageRepositoryProvider.overrideWithValue(usage),
        ],
        child: const LockoutApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set up Lockout'), findsOneWidget);
    expect(find.text('Usage access'), findsOneWidget);
    expect(find.text('Display over other apps'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Battery optimisation'), findsOneWidget);
    expect(find.text('0 of 4 granted'), findsOneWidget);
  });

  testWidgets('shows Home when every permission is granted', (tester) async {
    useTallScreen(tester);
    final permissions = FakePermissionsRepository(allGranted);
    final usage = FakeUsageRepository(
      summary: summaryOf([
        (packageName: 'com.instagram.android', seconds: 3900),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsRepositoryProvider.overrideWithValue(permissions),
          usageRepositoryProvider.overrideWithValue(usage),
          usagePollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
        ],
        child: const LockoutApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Time used today'), findsOneWidget);
    expect(find.text('1h 05m'), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('skipping onboarding lands on Home', (tester) async {
    useTallScreen(tester);
    final permissions = FakePermissionsRepository(PermissionSnapshot.none);
    final usage = FakeUsageRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsRepositoryProvider.overrideWithValue(permissions),
          usageRepositoryProvider.overrideWithValue(usage),
          usagePollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
        ],
        child: const LockoutApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('4 permissions missing'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
