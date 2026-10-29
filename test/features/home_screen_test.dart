import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/app.dart';
import 'package:lockout/core/di.dart';
import 'package:lockout/domain/entities/installed_app.dart';

import '../helpers/fakes.dart';
import '../helpers/test_surface.dart';

void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    required FakeUsageRepository usage,
    required FakePermissionsRepository permissions,
  }) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usageRepositoryProvider.overrideWithValue(usage),
          permissionsRepositoryProvider.overrideWithValue(permissions),
          usagePollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
        ],
        child: const LockoutApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

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

    await pumpHome(
      tester,
      usage: usage,
      permissions: FakePermissionsRepository(allGranted),
    );

    expect(find.text('TikTok'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('30m'), findsOneWidget);
    expect(find.text('10m'), findsOneWidget);
    expect(find.text('40m'), findsOneWidget); // combined total
    expect(find.text('Since 00:00 · 2 apps'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('falls back to the package name when the label is unknown', (
    tester,
  ) async {
    final usage = FakeUsageRepository(
      summary: summaryOf([(packageName: 'com.example.unknown', seconds: 120)]),
      apps: const [],
    );

    await pumpHome(
      tester,
      usage: usage,
      permissions: FakePermissionsRepository(allGranted),
    );

    expect(find.text('com.example.unknown'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows an error with retry when usage cannot be read', (
    tester,
  ) async {
    final usage = FakeUsageRepository(error: StateError('usage unavailable'));

    await pumpHome(
      tester,
      usage: usage,
      permissions: FakePermissionsRepository(allGranted),
    );

    expect(find.text("Couldn't reach the Android layer"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows the empty state when nothing was used today', (
    tester,
  ) async {
    await pumpHome(
      tester,
      usage: FakeUsageRepository(),
      permissions: FakePermissionsRepository(allGranted),
    );

    expect(find.textContaining('No usage recorded yet today'), findsOneWidget);
    expect(find.text('0m'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
