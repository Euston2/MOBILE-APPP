import '../entities/permission_snapshot.dart';

/// Contract for checking and requesting the special permissions.
abstract interface class PermissionsRepository {
  Future<PermissionSnapshot> getStatus();

  /// Opens the system screen where the user can grant [kind].
  /// Returns once the screen is launched; re-check with [getStatus] on resume.
  Future<void> openSettings(PermissionKind kind);
}
