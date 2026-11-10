import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/data/local/app_database.dart';
import 'package:lockout/data/repositories/drift_history_repository.dart';
import 'package:lockout/platform/lockout_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late DriftHistoryRepository repository;

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftHistoryRepository(
      // loadDays is a pure database read; the platform is only used by the
      // archive-import methods covered elsewhere.
      LockoutPlatform(channel: const MethodChannel('test/history')),
      database,
    );
  });

  tearDown(() => database.close());

  test('joins summaries and per-app usage, oldest first', () async {
    await database.saveDailyArchive(
      date: '2026-10-30',
      totalSeconds: 3900,
      limitSeconds: 3600,
      limitHitAt: DateTime(2026, 10, 30, 14),
      apps: const {'com.example.instagram': 3900},
      focusSeconds: 1800,
      lateNightSeconds: 300,
      lateNightApps: const {'com.example.instagram': 300},
    );
    await database.saveDailyArchive(
      date: '2026-10-28',
      totalSeconds: 1800,
      limitSeconds: 3600,
      limitHitAt: null,
      apps: const {'com.example.instagram': 1200, 'com.example.tiktok': 600},
      focusSeconds: 900,
      lateNightSeconds: 120,
      lateNightApps: const {'com.example.tiktok': 120},
    );

    final days = await repository.loadDays(
      start: DateTime(2026, 10, 25),
      end: DateTime(2026, 10, 31),
    );

    expect(days.map((day) => day.dateKey), ['2026-10-28', '2026-10-30']);
    expect(days.first.totalSeconds, 1800);
    expect(days.first.limitSeconds, 3600);
    expect(days.first.limitHitAt, isNull);
    expect(days.first.apps, {
      'com.example.instagram': 1200,
      'com.example.tiktok': 600,
    });
    expect(days.first.focusSeconds, 900);
    expect(days.first.lateNightSeconds, 120);
    expect(days.first.lateNightApps, {'com.example.tiktok': 120});
    expect(days.last.limitHitAt, DateTime(2026, 10, 30, 14));
    expect(days.last.focusSeconds, 1800);
    expect(days.last.lateNightSeconds, 300);
    expect(days.last.lateNightApps, {'com.example.instagram': 300});
  });

  test('uses start-inclusive and end-exclusive bounds', () async {
    for (final date in ['2026-10-29', '2026-10-30']) {
      await database.saveDailyArchive(
        date: date,
        totalSeconds: 600,
        limitSeconds: 0,
        limitHitAt: null,
        apps: const {},
      );
    }

    final days = await repository.loadDays(
      start: DateTime(2026, 10, 29),
      end: DateTime(2026, 10, 30),
    );

    expect(days, hasLength(1));
    expect(days.single.dateKey, '2026-10-29');
  });

  test('returns no days for an empty or inverted window', () async {
    await database.saveDailyArchive(
      date: '2026-10-30',
      totalSeconds: 600,
      limitSeconds: 0,
      limitHitAt: null,
      apps: const {},
    );

    expect(
      await repository.loadDays(
        start: DateTime(2026, 10, 30),
        end: DateTime(2026, 10, 30),
      ),
      isEmpty,
    );
    expect(
      await repository.loadDays(
        start: DateTime(2026, 10, 31),
        end: DateTime(2026, 10, 30),
      ),
      isEmpty,
    );
  });

  test('parses focus and late-night fields from the native archive', () async {
    const channel = MethodChannel('test/history-archive-fields');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method != 'getPendingArchives') return null;
          return <Map<String, Object?>>[
            {
              'date': '2026-10-31',
              'totalSeconds': 1200,
              'limitSeconds': 3600,
              'limitHitAtMs': 0,
              'focusSeconds': 2400,
              'lateNightSeconds': 180,
              'apps': [
                {'packageName': 'com.example.instagram', 'seconds': 1200},
              ],
              'lateNightApps': [
                {'packageName': 'com.example.instagram', 'seconds': 180},
              ],
            },
          ];
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final parsingRepository = DriftHistoryRepository(
      LockoutPlatform(channel: channel),
      database,
    );

    final archives = await parsingRepository.readPendingArchives();

    expect(archives, hasLength(1));
    expect(archives.single.focusSeconds, 2400);
    expect(archives.single.lateNightSeconds, 180);
    expect(archives.single.apps, {'com.example.instagram': 1200});
    expect(archives.single.lateNightApps, {'com.example.instagram': 180});
  });

  test('skips a summary row with an invalid date', () async {
    await database
        .into(database.dailySummaries)
        .insert(
          DailySummariesCompanion.insert(
            date: 'not-a-date',
            totalSeconds: 60,
            limitSeconds: 0,
          ),
        );
    await database.saveDailyArchive(
      date: '2026-10-30',
      totalSeconds: 600,
      limitSeconds: 0,
      limitHitAt: null,
      apps: const {},
    );

    final days = await repository.loadDays(
      start: DateTime(2026, 10, 25),
      end: DateTime(2026, 10, 31),
    );

    expect(days.map((day) => day.dateKey), ['2026-10-30']);
  });
}
