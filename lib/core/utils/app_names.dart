/// User-facing app labels.
///
/// Package names are internal identifiers. They are useful for platform calls
/// and storage, but should never be shown in the app, even when an old row or a
/// usage event has no friendly display name.
library;

const String unknownAppName = 'Unknown app';
const String removedAppName = 'Removed app';

/// Returns [displayName] when it is a real label, otherwise [fallback].
///
/// Older builds could store the package name as the display name when Android
/// did not expose a label; treating that as unknown keeps identifiers out of the
/// UI without losing the package key used for tracking.
String friendlyAppName(
  String packageName,
  String? displayName, {
  String fallback = unknownAppName,
}) {
  final name = displayName?.trim();
  if (name == null || name.isEmpty || name == packageName) return fallback;
  return name;
}
