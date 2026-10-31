import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/data/local/app_database.dart';
import 'package:lockout/data/repositories/drift_history_repository.dart';
import 'package:lockout/platform/lockout_platform.dart';

void main() {
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
    );
    await database.saveDailyArchive(
      date: '2026-10-28',
      totalSeconds: 1800,
      limitSeconds: 3600,
      limitHitAt: null,
      apps: const {'com.example.instagram': 1200, 'com.example.tiktok': 600},
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
    expect(days.last.limitHitAt, DateTime(2026, 10, 30, 14));
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
