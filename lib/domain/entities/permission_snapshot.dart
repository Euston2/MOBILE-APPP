/// The four special accesses Lockout needs before it can enforce a hard limit.
///
/// UI copy lives in the presentation layer; this enum is the stable contract
/// between domain and platform code.
enum PermissionKind {
  /// `PACKAGE_USAGE_STATS` — read per-app foreground time.
  usageAccess,

  /// `SYSTEM_ALERT_WINDOW` — draw the block screen above other apps.
  overlay,

  /// `POST_NOTIFICATIONS` — foreground-service notification and alerts.
  notifications,

  /// Battery-optimisation exemption — keep the watcher alive.
  batteryOptimization,
}

/// Snapshot of every permission Lockout cares about.
class PermissionSnapshot {
  const PermissionSnapshot({
    required this.usageAccess,
    required this.overlay,
    required this.notifications,
    required this.batteryOptimizationIgnored,
  });

  /// Nothing granted; useful for tests and initial states.
  static const PermissionSnapshot none = PermissionSnapshot(
    usageAccess: false,
    overlay: false,
    notifications: false,
    batteryOptimizationIgnored: false,
  );

  final bool usageAccess;
  final bool overlay;
  final bool notifications;
  final bool batteryOptimizationIgnored;

  bool isGranted(PermissionKind kind) => switch (kind) {
    PermissionKind.usageAccess => usageAccess,
    PermissionKind.overlay => overlay,
    PermissionKind.notifications => notifications,
    PermissionKind.batteryOptimization => batteryOptimizationIgnored,
  };

  List<PermissionKind> get granted =>
      PermissionKind.values.where(isGranted).toList(growable: false);

  List<PermissionKind> get missing => PermissionKind.values
      .where((kind) => !isGranted(kind))
      .toList(growable: false);

  bool get allGranted => missing.isEmpty;

  /// Tracking is impossible without usage access; everything else degrades
  /// blocking quality but does not stop the counter.
  bool get canTrack => usageAccess;

  @override
  bool operator ==(Object other) =>
      other is PermissionSnapshot &&
      other.usageAccess == usageAccess &&
      other.overlay == overlay &&
      other.notifications == notifications &&
      other.batteryOptimizationIgnored == batteryOptimizationIgnored;

  @override
  int get hashCode => Object.hash(
    usageAccess,
    overlay,
    notifications,
    batteryOptimizationIgnored,
  );
}
