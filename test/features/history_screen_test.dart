import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/utils/day_window.dart';
import 'package:lockout/domain/entities/history_day.dart';
import 'package:lockout/domain/entities/installed_app.dart';
import 'package:lockout/features/history/presentation/widgets/history_chart.dart';

import '../helpers/fake_stores.dart';
import '../helpers/fakes.dart';
import '../helpers/pump_lockout.dart';

void main() {
  DateTime daysAgo(int days) {
    final today = startOfLocalDay(DateTime.now());
    return DateTime(today.year, today.month, today.day - days);
  }

  testWidgets('opens from Home and explains that history starts at midnight', (
    tester,
  ) async {
    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
    );

    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.text('No history yet'), findsOneWidget);
    expect(find.byIcon(Icons.ios_share), findsOneWidget);

    final share = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.ios_share),
    );
    expect(share.onPressed, isNull);

    await disposeTestApp(tester);
  });

  testWidgets('shows stats, chart, days and a shareable CSV', (tester) async {
    final exporter = FakeHistoryExporter();
    final history = FakeHistoryRepository(
      days: [
        HistoryDay(
          date: daysAgo(1),
          totalSeconds: 1800,
          limitSeconds: 3600,
          apps: const {'com.instagram.android': 1800},
        ),
        HistoryDay(
          date: daysAgo(2),
          totalSeconds: 3600,
          limitSeconds: 3600,
          limitHitAt: DateTime(
            daysAgo(2).year,
            daysAgo(2).month,
            daysAgo(2).day,
            14,
            5,
          ),
          apps: const {
            'com.instagram.android': 2400,
            'com.zhiliaoapp.musically': 1200,
          },
        ),
      ],
    );

    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(
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
      history: history,
      exporter: exporter,
    );

    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();

    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('2 of 7 days recorded'), findsOneWidget);
    expect(find.text('1h 30m'), findsOneWidget); // total
    expect(find.text('45m'), findsOneWidget); // tracked-day average
    expect(find.text('Over limit'), findsOneWidget);
    expect(find.byType(HistoryChart), findsOneWidget);
    expect(find.text('Limit reached at 14:05'), findsOneWidget);
    expect(find.text('30m left of 1h'), findsOneWidget);

    await tester.tap(find.text('Limit reached at 14:05'));
    await tester.pumpAndSettle();

    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('TikTok'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle();

    expect(exporter.csvs, hasLength(1));
    expect(exporter.subjects.single, 'Lockout history (7 days)');
    final csv = exporter.csvs.single;
    expect(
      csv,
      startsWith('date,total_seconds,limit_seconds,limit_hit_at,apps\r\n'),
    );
    expect(csv, contains(localDateKey(daysAgo(2))));
    expect(csv, contains(localDateKey(daysAgo(1))));
    expect(csv, contains('com.instagram.android=2400'));
    expect(csv.split('\r\n').where((line) => line.isNotEmpty), hasLength(3));

    await disposeTestApp(tester);
  });

  testWidgets('switches the window from 7 to 30 days', (tester) async {
    final history = FakeHistoryRepository(
      days: [
        for (var offset = 1; offset <= 10; offset++)
          HistoryDay(date: daysAgo(offset), totalSeconds: 600, limitSeconds: 0),
      ],
    );

    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      history: history,
    );

    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();

    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('7 of 7 days recorded'), findsOneWidget);

    await tester.tap(find.text('30 days'));
    await tester.pumpAndSettle();

    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('10 of 30 days recorded'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('shows a load error and recovers on retry', (tester) async {
    final history = FakeHistoryRepository(
      loadError: StateError('database is locked'),
    );

    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      history: history,
    );

    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn\'t load your history'), findsOneWidget);
    expect(
      find.text('Your history is still on this phone. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('database is locked'), findsNothing);

    history.loadError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('No history yet'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('reports a share failure instead of crashing', (tester) async {
    final exporter = FakeHistoryExporter(error: StateError('no share target'));
    final history = FakeHistoryRepository(
      days: [HistoryDay(date: daysAgo(1), totalSeconds: 600, limitSeconds: 0)],
    );

    await pumpLockoutApp(
      tester,
      permissions: FakePermissionsRepository(allGranted),
      usage: FakeUsageRepository(),
      history: history,
      exporter: exporter,
    );

    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle();

    expect(
      find.text("Couldn't share your history. Please try again."),
      findsOneWidget,
    );
    expect(find.textContaining('no share target'), findsNothing);

    await disposeTestApp(tester);
  });
}
