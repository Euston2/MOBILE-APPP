import '../../domain/entities/device_diagnostics.dart';
import '../../domain/repositories/diagnostics_repository.dart';
import '../../platform/lockout_platform.dart';

/// [DiagnosticsRepository] backed by the single Android method channel.
class AndroidDiagnosticsRepository implements DiagnosticsRepository {
  const AndroidDiagnosticsRepository(this._platform);

  final LockoutPlatform _platform;

  @override
  Future<DeviceDiagnostics> load() async =>
      parse(await _platform.getDiagnostics());

  @override
  Future<void> openOemAutostartSettings() =>
      _platform.openOemAutostartSettings();

  @override
  Future<void> openExactAlarmSettings() => _platform.openExactAlarmSettings();

  /// Converts the raw native snapshot into the domain entity.
  ///
  /// Kept public so channel-shape tests can run without a real Android device.
  static DeviceDiagnostics parse(Map<Object?, Object?> raw) {
    final events = <DiagnosticEvent>[];
    final rawEvents = raw['events'];
    if (rawEvents is List) {
      for (final item in rawEvents) {
        if (item is! Map) continue;
        final timestampMs = _int(item['timestampMs']);
        final message = _text(item['message']);
        if (timestampMs <= 0 || message.isEmpty) continue;
        events.add(
          DiagnosticEvent(
            at: DateTime.fromMillisecondsSinceEpoch(timestampMs),
            level: _text(item['level'], fallback: 'INFO'),
            message: message,
          ),
        );
      }
    }

    final lastArchivedDate = _text(raw['lastArchivedDate']);

    return DeviceDiagnostics(
      manufacturer: _text(raw['manufacturer'], fallback: 'Android'),
      brand: _text(raw['brand']),
      model: _text(raw['model']),
      sdkInt: _int(raw['sdkInt']),
      usageAccess: raw['usageAccess'] == true,
      overlay: raw['overlay'] == true,
      notifications: raw['notifications'] == true,
      batteryOptimizationIgnored: raw['batteryOptimizationIgnored'] == true,
      exactAlarmsAllowed: raw['exactAlarmsAllowed'] == true,
      powerSaveMode: raw['powerSaveMode'] == true,
      serviceConfigured: raw['serviceConfigured'] == true,
      isLocked: raw['isLocked'] == true,
      lockedAt: _date(raw['lockedAtMs']),
      nextResetAt: _date(raw['nextResetAtMs']),
      limitSeconds: _int(raw['limitSeconds']),
      monitoredCount: _int(raw['monitoredCount']),
      pendingConfigured: raw['pendingConfigured'] == true,
      lastArchivedDate: lastArchivedDate.isEmpty ? null : lastArchivedDate,
      events: List.unmodifiable(events.take(50)),
    );
  }

  static int _int(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v) ?? 0,
    _ => 0,
  };

  static String _text(Object? value, {String fallback = ''}) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  static DateTime? _date(Object? value) {
    final milliseconds = _int(value);
    if (milliseconds <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
}
