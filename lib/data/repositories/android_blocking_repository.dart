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
    isLocked: config.isLocked,
    nextResetAt: config.nextResetAt,
  );

  @override
  Future<void> stop() => _platform.stopBlocking();
}
