/// The configuration the native blocking service enforces.
///
/// Dart owns the policy (which apps, what limit, is the lock active); the
/// service only reads this snapshot. It is rebuilt whenever settings or the
/// monitored-app list change and pushed over the platform channel, where Kotlin
/// caches it so blocking keeps working after the Flutter process is killed.
class BlockingConfig {
  const BlockingConfig({
    required this.monitoredPackages,
    required this.dailyLimitSeconds,
    required this.isLocked,
    required this.nextResetAt,
  });

  final Set<String> monitoredPackages;
  final int dailyLimitSeconds;
  final bool isLocked;
  final DateTime nextResetAt;

  /// Nothing to enforce: no limit, or no apps selected.
  bool get isActive => dailyLimitSeconds > 0 && monitoredPackages.isNotEmpty;

  @override
  String toString() =>
      'BlockingConfig(apps: ${monitoredPackages.length}, '
      'limit: ${dailyLimitSeconds}s, locked: $isLocked)';
}
