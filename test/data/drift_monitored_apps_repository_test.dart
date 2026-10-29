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
}
