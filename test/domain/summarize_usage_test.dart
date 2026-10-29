import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/entities/app_usage.dart';
import 'package:lockout/domain/entities/usage_summary.dart';
import 'package:lockout/domain/usecases/summarize_usage.dart';

void main() {
  final start = DateTime(2026, 10, 29);
  final end = DateTime(2026, 10, 29, 14, 30);

  UsageSummary summarise(List<AppUsage> entries, {Set<String>? monitored}) {
    return summarizeUsage(
      windowStart: start,
      windowEnd: end,
      entries: entries,
      monitoredPackages: monitored,
    );
  }

  test('sums usage per package and sorts descending', () {
    final summary = summarise([
      const AppUsage(packageName: 'com.instagram.android', seconds: 600),
      const AppUsage(packageName: 'com.zhiliaoapp.musically', seconds: 1800),
      const AppUsage(packageName: 'com.instagram.android', seconds: 300),
    ]);

    expect(summary.totalSeconds, 2700);
    expect(summary.perApp.first.packageName, 'com.zhiliaoapp.musically');
    expect(summary.perApp.first.seconds, 1800);
    expect(summary.perApp.last.seconds, 900);
  });

  test('filters to monitored packages when provided', () {
    final summary = summarise(
      [
        const AppUsage(packageName: 'com.instagram.android', seconds: 600),
        const AppUsage(packageName: 'com.android.chrome', seconds: 1200),
      ],
      monitored: {'com.instagram.android'},
    );

    expect(summary.perApp, hasLength(1));
    expect(summary.totalSeconds, 600);
  });

  test('drops empty packages and non-positive durations', () {
    final summary = summarise([
      const AppUsage(packageName: '', seconds: 500),
      const AppUsage(packageName: 'com.whatsapp', seconds: 0),
      const AppUsage(packageName: 'com.snapchat.android', seconds: -30),
      const AppUsage(packageName: 'com.google.android.youtube', seconds: 120),
    ]);

    expect(summary.perApp, hasLength(1));
    expect(summary.totalSeconds, 120);
  });

  test('empty input gives an empty summary', () {
    final summary = summarise([]);

    expect(summary.isEmpty, isTrue);
    expect(summary.totalSeconds, 0);
    expect(summary.topApp, isNull);
  });

  test('keeps the requested window on the summary', () {
    final summary = summarise([]);

    expect(summary.windowStart, start);
    expect(summary.windowEnd, end);
  });
}
