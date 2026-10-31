/// The configuration the native blocking service enforces.
///
/// Dart owns the policy (which apps, what limit, is the lock active); the
/// service only reads this snapshot. It is rebuilt whenever settings or the
/// monitored-app list change and pushed over the platform channel, where Kotlin
/// caches it so blocking keeps working after the Flutter process is killed.
///
/// A scheduled change is sent as a complete second configuration
/// ([pendingPackages] + [pendingLimitSeconds] + [pendingEffectiveAt]): Kotlin
/// switches to it when the clock reaches the effective instant, so the next
/// day's limit is enforced even if Flutter never runs at midnight.
class BlockingConfig {
  const BlockingConfig({
    required this.monitoredPackages,
    required this.dailyLimitSeconds,
    required this.isLocked,
    required this.nextResetAt,
    this.pendingPackages = const {},
    this.pendingLimitSeconds = 0,
    this.pendingEffectiveAt,
    this.lockedAt,
  });

  /// Apps monitored today.
  final Set<String> monitoredPackages;

  /// Combined limit that applies today. 0 means "no limit".
  final int dailyLimitSeconds;

  /// Apps monitored from [pendingEffectiveAt] onwards.
  final Set<String> pendingPackages;

  /// Limit that applies from [pendingEffectiveAt] onwards (0 = none).
  final int pendingLimitSeconds;

  /// Local midnight at which the pending configuration takes over.
  final DateTime? pendingEffectiveAt;

  final bool isLocked;

  /// When the current lock was stamped.
  final DateTime? lockedAt;

  /// Local midnight at which [isLocked] expires.
  final DateTime nextResetAt;

  bool get hasPendingConfig =>
      pendingEffectiveAt != null &&
      pendingLimitSeconds > 0 &&
      pendingPackages.isNotEmpty;

  /// Nothing to enforce: neither today nor a scheduled day has a usable limit.
  bool get isActive =>
      (dailyLimitSeconds > 0 && monitoredPackages.isNotEmpty) ||
      hasPendingConfig;

  @override
  String toString() =>
      'BlockingConfig(apps: ${monitoredPackages.length}, '
      'limit: ${dailyLimitSeconds}s, pendingApps: ${pendingPackages.length}, '
      'pendingLimit: ${pendingLimitSeconds}s, locked: $isLocked)';
}
