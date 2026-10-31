/// An app the user picked for tracking.
///
/// [isEnabled] is the selection used *today*. When the user changes the
/// selection while a limit/app set is already active, the change is scheduled:
/// [pendingEnabled] is the value that becomes [isEnabled] at the next local
/// midnight. Null means "no scheduled change for this app".
class MonitoredApp {
  const MonitoredApp({
    required this.packageName,
    required this.displayName,
    this.isEnabled = true,
    this.pendingEnabled,
  });

  final String packageName;
  final String displayName;
  final bool isEnabled;
  final bool? pendingEnabled;

  /// Whether the app should count after pending changes are applied.
  bool get scheduledEnabled => pendingEnabled ?? isEnabled;

  MonitoredApp copyWith({
    String? displayName,
    bool? isEnabled,
    bool? pendingEnabled,
    bool clearPendingEnabled = false,
  }) => MonitoredApp(
    packageName: packageName,
    displayName: displayName ?? this.displayName,
    isEnabled: isEnabled ?? this.isEnabled,
    pendingEnabled: clearPendingEnabled
        ? null
        : (pendingEnabled ?? this.pendingEnabled),
  );

  @override
  bool operator ==(Object other) =>
      other is MonitoredApp &&
      other.packageName == packageName &&
      other.displayName == displayName &&
      other.isEnabled == isEnabled &&
      other.pendingEnabled == pendingEnabled;

  @override
  int get hashCode =>
      Object.hash(packageName, displayName, isEnabled, pendingEnabled);

  @override
  String toString() =>
      'MonitoredApp($packageName, enabled: $isEnabled, '
      'pending: $pendingEnabled)';
}
