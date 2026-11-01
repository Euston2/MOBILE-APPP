import '../../../domain/entities/device_diagnostics.dart';

/// Builds the plain-text report copied from Protection check.
///
/// It contains only device/permission/config state and the native event
/// messages, which are already sanitised to avoid app content.
String buildDiagnosticsReport(DeviceDiagnostics diagnostics) {
  final device = [
    diagnostics.manufacturer,
    if (diagnostics.model.isNotEmpty) diagnostics.model,
  ].join(' ');
  final lines = <String>[
    'Lockout diagnostics',
    'Device: $device (Android SDK ${diagnostics.sdkInt})',
    'Battery saver now: ${diagnostics.powerSaveMode ? 'on' : 'off'}',
    'Essential checks: ${diagnostics.passedRequiredChecks}/'
        '${DeviceDiagnostics.requiredCheckCount}',
    'Usage access: ${_status(diagnostics.usageAccess)}',
    'Overlay: ${_status(diagnostics.overlay)}',
    'Notifications: ${_status(diagnostics.notifications)}',
    'Battery optimisation ignored: '
        '${_status(diagnostics.batteryOptimizationIgnored)}',
    'Exact alarm access: ${_status(diagnostics.exactAlarmsAllowed)}',
    'Service configured: ${_status(diagnostics.serviceConfigured)}',
    'Locked: ${_status(diagnostics.isLocked)}',
    'Limit: ${diagnostics.limitSeconds}s',
    'Monitored apps: ${diagnostics.monitoredCount}',
    'Pending change: ${_status(diagnostics.pendingConfigured)}',
    'Next reset: ${_time(diagnostics.nextResetAt)}',
    'Last archived day: ${diagnostics.lastArchivedDate ?? 'none'}',
    'Recent events:',
  ];

  if (diagnostics.events.isEmpty) {
    lines.add('  (none)');
  } else {
    for (final event in diagnostics.events) {
      lines.add(
        '  ${formatDiagnosticTimestamp(event.at)} '
        '${event.level} ${event.message}',
      );
    }
  }

  return lines.join('\n');
}

/// `yyyy-MM-dd HH:mm:ss` in the device's local time, without `intl`.
String formatDiagnosticTimestamp(DateTime at) =>
    '${at.year.toString().padLeft(4, '0')}-'
    '${at.month.toString().padLeft(2, '0')}-'
    '${at.day.toString().padLeft(2, '0')} '
    '${_clock(at)}';

/// `HH:mm:ss`, used in the compact event rows on screen.
String formatDiagnosticClock(DateTime at) => _clock(at);

String _clock(DateTime at) =>
    '${at.hour.toString().padLeft(2, '0')}:'
    '${at.minute.toString().padLeft(2, '0')}:'
    '${at.second.toString().padLeft(2, '0')}';

String _status(bool value) => value ? 'yes' : 'no';

String _time(DateTime? value) =>
    value == null ? 'none' : formatDiagnosticTimestamp(value);
