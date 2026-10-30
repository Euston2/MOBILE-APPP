import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../domain/entities/blocking_config.dart';
import '../../limits/presentation/monitored_apps_controller.dart';
import '../../limits/presentation/settings_controller.dart';

/// Snapshot of what the native service should enforce right now.
///
/// Null until settings have loaded; the watcher is left untouched in that case
/// so a cold start does not briefly stop an already-running service.
final blockingConfigProvider = Provider<BlockingConfig?>((ref) {
  final settings = ref.watch(settingsControllerProvider).value;
  if (settings == null) return null;

  return BlockingConfig(
    monitoredPackages: ref.watch(enabledPackagesProvider),
    dailyLimitSeconds: settings.dailyLimitSeconds,
    isLocked: settings.isLocked,
    nextResetAt: settings.nextResetAt,
  );
});

/// Keeps the Kotlin watcher in sync with [blockingConfigProvider].
///
/// Watched once by the app gate, so every settings/app-selection change
/// (including the first load) reaches the service without each screen having to
/// remember to call it.
final blockingSyncProvider = FutureProvider<void>((ref) async {
  final config = ref.watch(blockingConfigProvider);
  final repository = ref.watch(blockingRepositoryProvider);

  if (config == null) return;
  if (!config.isActive) {
    await repository.stop();
    return;
  }
  await repository.sync(config);
});
