/// A launchable app installed on the device.
///
/// Only the package name, label and a system flag are exposed; no icon or
/// personal data is read.
class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.displayName,
    this.isSystem = false,
  });

  final String packageName;
  final String displayName;
  final bool isSystem;

  @override
  bool operator ==(Object other) =>
      other is InstalledApp && other.packageName == packageName;

  @override
  int get hashCode => packageName.hashCode;

  @override
  String toString() => 'InstalledApp($packageName)';
}
