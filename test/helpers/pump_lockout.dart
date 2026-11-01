import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/app.dart';
import 'package:lockout/core/di.dart';

import 'fake_stores.dart';
import 'fakes.dart';
import 'test_surface.dart';

/// Boots the real app with fake repositories.
///
/// Polling is stretched to an hour so timers never fire mid-test; the tree is
/// unmounted by [disposeTestApp] to cancel the timer before teardown.
Future<void> pumpLockoutApp(
  WidgetTester tester, {
  required FakePermissionsRepository permissions,
  required FakeUsageRepository usage,
  FakeSettingsRepository? settings,
  FakeMonitoredAppsRepository? monitored,
  FakeBlockingRepository? blocking,
  FakeHistoryRepository? history,
  FakeHistoryExporter? exporter,
  FakeDiagnosticsRepository? diagnostics,
}) async {
  useTallScreen(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        permissionsRepositoryProvider.overrideWithValue(permissions),
        usageRepositoryProvider.overrideWithValue(usage),
        settingsRepositoryProvider.overrideWithValue(
          settings ?? FakeSettingsRepository(),
        ),
        monitoredAppsRepositoryProvider.overrideWithValue(
          monitored ?? FakeMonitoredAppsRepository(),
        ),
        blockingRepositoryProvider.overrideWithValue(
          blocking ?? FakeBlockingRepository(),
        ),
        historyRepositoryProvider.overrideWithValue(
          history ?? FakeHistoryRepository(),
        ),
        historyExporterProvider.overrideWithValue(
          exporter ?? FakeHistoryExporter(),
        ),
        diagnosticsRepositoryProvider.overrideWithValue(
          diagnostics ?? FakeDiagnosticsRepository(),
        ),
        usagePollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
      child: const LockoutApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Unmounts the app so provider disposal cancels polling timers.
Future<void> disposeTestApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}
