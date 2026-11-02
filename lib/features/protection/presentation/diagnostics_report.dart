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
    'Lockout support report',
    'Device: $device (Android SDK ${diagnostics.sdkInt})',
    'Battery saver now: ${diagnostics.powerSaveMode ? 'on' : 'off'}',
    'Setup checks: ${diagnostics.passedRequiredChecks}/'
        '${DeviceDiagnostics.requiredCheckCount}',
    'App activity access: ${_status(diagnostics.usageAccess)}',
    'Show over other apps: ${_status(diagnostics.overlay)}',
    'Notifications: ${_status(diagnostics.notifications)}',
    'Battery saver exemption: '
        '${_status(diagnostics.batteryOptimizationIgnored)}',
    'On-time reset access: ${_status(diagnostics.exactAlarmsAllowed)}',
    'Protection configured: ${_status(diagnostics.serviceConfigured)}',
    'Limit locked: ${_status(diagnostics.isLocked)}',
    'Limit: ${diagnostics.limitSeconds}s',
    'Apps tracked: ${diagnostics.monitoredCount}',
    'Scheduled change: ${_status(diagnostics.pendingConfigured)}',
    'Next reset: ${_time(diagnostics.nextResetAt)}',
    'Last archived day: ${diagnostics.lastArchivedDate ?? 'none'}',
    'Recent activity:',
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

/// Plain-language version of a native event for the in-app activity list.
///
/// The raw message is still kept in the copied support report, where technical
/// detail helps. This mapping only covers the events the app currently writes.
String friendlyDiagnosticMessage(DiagnosticEvent event) {
  final message = event.message;
  if (message.startsWith('service started')) return 'Protection started';
  if (message.startsWith('service start requested')) {
    return 'Protection starting';
  }
  if (message.startsWith('service stopped')) return 'Protection stopped';
  if (message.startsWith('service restarted')) return 'Protection restarted';
  if (message.startsWith('service destroyed')) {
    return 'Android stopped protection';
  }
  if (message.startsWith('task removed')) return 'Protection kept running';
  if (message.startsWith('config synced')) return 'Limit and apps updated';
  if (message.startsWith('config sync failed')) {
    return 'Could not update protection';
  }
  if (message.startsWith('limit lock set')) return 'Daily limit locked';
  if (message.startsWith('daily lock cleared')) return 'Daily limit reset';
  if (message.startsWith('midnight alarm')) return 'Midnight reset checked';
  if (message.startsWith('reset alarm armed')) {
    return 'Midnight reset scheduled';
  }
  if (message.startsWith('exact alarm')) {
    return 'Midnight reset may be delayed';
  }
  if (message.startsWith('scheduled app/limit change applied')) {
    return 'New settings started';
  }
  if (message.startsWith('archived ')) return 'Yesterday saved to history';
  if (message.startsWith('usage query failed')) {
    return 'Could not save yesterday';
  }
  if (message.startsWith('system event:')) return 'Phone woke Lockout';
  if (message.startsWith('no OEM autostart screen')) {
    return 'Opened phone settings';
  }
  if (message.startsWith('could not open settings')) {
    return 'Could not open phone settings';
  }
  if (message.startsWith('could not restart watcher')) {
    return 'Protection needs a restart';
  }
  if (message.startsWith('foreground service start failed')) {
    return 'Protection could not start';
  }
  if (message.startsWith('blocking stopped by user')) {
    return 'Block screen closed';
  }
  if (message.startsWith('could not arm the reset alarm')) {
    return 'Midnight reset may be delayed';
  }
  return event.level == 'ERROR'
      ? 'Something went wrong'
      : event.level == 'WARN'
      ? 'Lockout needs attention'
      : 'Lockout activity';
}

/// Short, friendly label for the native log level.
String friendlyDiagnosticLevel(String level) => switch (level) {
  'ERROR' => 'Issue',
  'WARN' => 'Notice',
  _ => 'Update',
};

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
