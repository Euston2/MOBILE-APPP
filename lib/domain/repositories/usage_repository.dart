import '../entities/installed_app.dart';
import '../entities/usage_summary.dart';

/// Contract for reading usage data from the device.
///
/// Implemented by `AndroidUsageRepository` over a MethodChannel, faked in tests.
abstract interface class UsageRepository {
  /// Foreground usage between [start] and [end], optionally restricted to
  /// [monitoredPackages] (all apps when null).
  Future<UsageSummary> getUsageForWindow({
    required DateTime start,
    required DateTime end,
    Set<String>? monitoredPackages,
  });

  /// Apps with a launcher entry, excluding Lockout itself.
  Future<List<InstalledApp>> getInstalledApps();
}
