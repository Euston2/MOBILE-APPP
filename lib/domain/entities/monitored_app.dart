/// An app the user picked for tracking.
class MonitoredApp {
  const MonitoredApp({
    required this.packageName,
    required this.displayName,
    this.isEnabled = true,
  });

  final String packageName;
  final String displayName;
  final bool isEnabled;

  MonitoredApp copyWith({String? displayName, bool? isEnabled}) => MonitoredApp(
    packageName: packageName,
    displayName: displayName ?? this.displayName,
    isEnabled: isEnabled ?? this.isEnabled,
  );

  @override
  bool operator ==(Object other) =>
      other is MonitoredApp &&
      other.packageName == packageName &&
      other.displayName == displayName &&
      other.isEnabled == isEnabled;

  @override
  int get hashCode => Object.hash(packageName, displayName, isEnabled);
}
