import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/data/local/app_database.dart';
import 'package:lockout/data/repositories/drift_monitored_apps_repository.dart';
import 'package:lockout/domain/entities/monitored_app.dart';

void main() {
  late AppDatabase database;
  late DriftMonitoredAppsRepository repository;

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftMonitoredAppsRepository(database);
  });

  tearDown(() => database.close());

  test('starts empty', () async {
    expect(await repository.getAll(), isEmpty);
  });

  test(
    'replaceAll persists apps and replaces the previous selection',
    () async {
      await repository.replaceAll(const [
        MonitoredApp(
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
        ),
        MonitoredApp(
          packageName: 'com.zhiliaoapp.musically',
          displayName: 'TikTok',
        ),
      ]);

      final firstRead = await repository.getAll();
      expect(firstRead.map((app) => app.packageName), [
        'com.instagram.android',
        'com.zhiliaoapp.musically',
      ]);

      await repository.replaceAll(const [
        MonitoredApp(
          packageName: 'com.zhiliaoapp.musically',
          displayName: 'TikTok',
          isEnabled: false,
        ),
      ]);

      final secondRead = await repository.getAll();
      expect(secondRead, hasLength(1));
      expect(secondRead.single.packageName, 'com.zhiliaoapp.musically');
      expect(secondRead.single.isEnabled, isFalse);
    },
  );

  test('persists a pending selection change', () async {
    await repository.replaceAll(const [
      MonitoredApp(
        packageName: 'com.instagram.android',
        displayName: 'Instagram',
        pendingEnabled: false,
      ),
      MonitoredApp(
        packageName: 'com.zhiliaoapp.musically',
        displayName: 'TikTok',
        isEnabled: false,
        pendingEnabled: true,
      ),
    ]);

    final rows = await repository.getAll();
    final byPackage = {for (final app in rows) app.packageName: app};
    expect(byPackage['com.instagram.android']?.isEnabled, isTrue);
    expect(byPackage['com.instagram.android']?.pendingEnabled, isFalse);
    expect(byPackage['com.zhiliaoapp.musically']?.isEnabled, isFalse);
    expect(byPackage['com.zhiliaoapp.musically']?.pendingEnabled, isTrue);
  });

  test('saves archive rows idempotently', () async {
    Future<void> save() => database.saveDailyArchive(
      date: '2026-10-30',
      totalSeconds: 3900,
      limitSeconds: 3600,
      limitHitAt: DateTime(2026, 10, 30, 14),
      apps: const {
        'com.instagram.android': 3000,
        'com.zhiliaoapp.musically': 900,
      },
    );

    await save();
    await save();

    final summaries = await database.select(database.dailySummaries).get();
    expect(summaries, hasLength(1));
    expect(summaries.single.date, '2026-10-30');
    expect(summaries.single.totalSeconds, 3900);
    expect(summaries.single.limitSeconds, 3600);
    expect(summaries.single.limitHitAt, DateTime(2026, 10, 30, 14));

    final usage = await database.select(database.dailyUsages).get();
    expect(usage, hasLength(2));
    expect(
      {for (final row in usage) row.packageName: row.totalSeconds},
      {'com.instagram.android': 3000, 'com.zhiliaoapp.musically': 900},
    );
  });
}
