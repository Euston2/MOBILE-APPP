import '../entities/device_diagnostics.dart';

/// Read-only health snapshot and the two Stage 6 settings shortcuts.
///
/// The permission shortcuts remain on [PermissionsRepository]; these are the
/// extras that only the Protection screen needs.
abstract interface class DiagnosticsRepository {
  Future<DeviceDiagnostics> load();

  /// Best-effort shortcut to the manufacturer autostart screen.
  Future<void> openOemAutostartSettings();

  /// Opens the Android 12+ exact-alarm access screen.
  Future<void> openExactAlarmSettings();
}
