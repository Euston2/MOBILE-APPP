import '../../domain/entities/permission_snapshot.dart';
import '../../domain/repositories/permissions_repository.dart';
import '../../platform/lockout_platform.dart';

/// [PermissionsRepository] that asks the Kotlin layer for the real OS state.
class AndroidPermissionsRepository implements PermissionsRepository {
  const AndroidPermissionsRepository(this._platform);

  final LockoutPlatform _platform;

  @override
  Future<PermissionSnapshot> getStatus() async {
    final raw = await _platform.getPermissionStatus();
    return PermissionSnapshot(
      usageAccess: raw['usageAccess'] ?? false,
      overlay: raw['overlay'] ?? false,
      notifications: raw['notifications'] ?? false,
      batteryOptimizationIgnored: raw['batteryOptimizationIgnored'] ?? false,
    );
  }

  @override
  Future<void> openSettings(PermissionKind kind) => switch (kind) {
    PermissionKind.usageAccess => _platform.openUsageAccessSettings(),
    PermissionKind.overlay => _platform.openOverlaySettings(),
    PermissionKind.notifications => _platform.openNotificationSettings(),
    PermissionKind.batteryOptimization =>
      _platform.openBatteryOptimizationSettings(),
  };
}
