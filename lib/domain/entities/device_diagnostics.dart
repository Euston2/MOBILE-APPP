/// One entry from the bounded native event log.
///
/// The native layer writes event types and counts only; package names, app
/// labels and usage content never appear here.
class DiagnosticEvent {
  const DiagnosticEvent({
    required this.at,
    required this.level,
    required this.message,
  });

  final DateTime at;

  /// `INFO`, `WARN` or `ERROR`.
  final String level;

  final String message;
}

/// Read-only snapshot used by the Protection check screen.
///
/// This is deliberately a plain entity: the Android repository parses the
/// method-channel map into this shape, and the screen/report code never sees
/// platform types.
class DeviceDiagnostics {
  const DeviceDiagnostics({
    this.manufacturer = 'Android',
    this.brand = '',
    this.model = '',
    this.sdkInt = 0,
    this.usageAccess = false,
    this.overlay = false,
    this.notifications = false,
    this.batteryOptimizationIgnored = false,
    this.exactAlarmsAllowed = false,
    this.powerSaveMode = false,
    this.serviceConfigured = false,
    this.isLocked = false,
    this.lockedAt,
    this.nextResetAt,
    this.limitSeconds = 0,
    this.monitoredCount = 0,
    this.pendingConfigured = false,
    this.lastArchivedDate,
    this.events = const [],
  });

  final String manufacturer;
  final String brand;
  final String model;
  final int sdkInt;

  final bool usageAccess;
  final bool overlay;
  final bool notifications;
  final bool batteryOptimizationIgnored;

  /// Exact `AlarmManager` access (always true before Android 12).
  final bool exactAlarmsAllowed;

  /// Whether the OS battery saver is currently on.
  final bool powerSaveMode;

  /// Whether an enforcement config is cached (not proof the service is alive).
  final bool serviceConfigured;

  final bool isLocked;
  final DateTime? lockedAt;
  final DateTime? nextResetAt;
  final int limitSeconds;
  final int monitoredCount;
  final bool pendingConfigured;

  /// `yyyy-MM-dd` of the last finished day Kotlin archived, if any.
  final String? lastArchivedDate;

  /// Oldest first, capped by the native log.
  final List<DiagnosticEvent> events;

  /// Essential checks for hard blocking. Exact-alarm access is a precision
  /// improvement, not a requirement, so it is shown separately.
  static const int requiredCheckCount = 4;

  int get passedRequiredChecks => [
    usageAccess,
    overlay,
    notifications,
    batteryOptimizationIgnored,
  ].where((passed) => passed).length;

  bool get allRequiredChecks => passedRequiredChecks == requiredCheckCount;
}
