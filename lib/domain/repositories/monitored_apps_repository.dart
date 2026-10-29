import '../entities/monitored_app.dart';

/// Contract for the selected-apps table.
abstract interface class MonitoredAppsRepository {
  Future<List<MonitoredApp>> getAll();

  /// Replaces the selection atomically (removed apps are deleted).
  Future<void> replaceAll(List<MonitoredApp> apps);
}
