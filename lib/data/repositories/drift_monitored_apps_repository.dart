import 'package:drift/drift.dart';

import '../../domain/entities/monitored_app.dart';
import '../../domain/repositories/monitored_apps_repository.dart';
import '../local/app_database.dart';

/// [MonitoredAppsRepository] backed by the drift `monitored_apps` table.
class DriftMonitoredAppsRepository implements MonitoredAppsRepository {
  DriftMonitoredAppsRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<MonitoredApp>> getAll() async {
    final rows = await _database.allMonitoredApps();
    return List.unmodifiable(
      rows.map(
        (row) => MonitoredApp(
          packageName: row.packageName,
          displayName: row.displayName,
          isEnabled: row.isEnabled,
        ),
      ),
    );
  }

  @override
  Future<void> replaceAll(List<MonitoredApp> apps) {
    return _database.replaceMonitoredApps([
      for (final app in apps)
        MonitoredAppsCompanion.insert(
          packageName: app.packageName,
          displayName: app.displayName,
          isEnabled: Value(app.isEnabled),
        ),
    ]);
  }
}
