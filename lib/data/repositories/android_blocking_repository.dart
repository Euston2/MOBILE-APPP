import '../../domain/entities/blocking_config.dart';
import '../../domain/repositories/blocking_repository.dart';
import '../../platform/lockout_platform.dart';

/// Pushes [BlockingConfig] to the Kotlin foreground service.
class AndroidBlockingRepository implements BlockingRepository {
  const AndroidBlockingRepository(this._platform);

  final LockoutPlatform _platform;

  @override
  Future<void> sync(BlockingConfig config) => _platform.setBlockingConfig(
    monitoredPackages: config.monitoredPackages,
    dailyLimitSeconds: config.dailyLimitSeconds,
    pendingPackages: config.pendingPackages,
    pendingLimitSeconds: config.pendingLimitSeconds,
    pendingEffectiveAt: config.pendingEffectiveAt,
    isLocked: config.isLocked,
    lockedAt: config.lockedAt,
    nextResetAt: config.nextResetAt,
    overnightLockEnabled: config.overnightLockEnabled,
    studyEndsAt: config.studyEndsAt,
    focusGoalSeconds: config.focusGoalSeconds,
    focusAutoBlockEnabled: config.focusAutoBlockEnabled,
    focusCutoffMinuteOfDay: config.focusCutoffMinuteOfDay,
    focusBaseSeconds: config.focusBaseSeconds,
    focusDayStart: config.focusDayStart,
    focusSessionStartedAt: config.focusSessionStartedAt,
    focusSessionEndsAt: config.focusSessionEndsAt,
  );

  @override
  Future<void> stop() => _platform.stopBlocking();
}
