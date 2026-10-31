import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../domain/entities/monitored_app.dart';
import '../../../domain/usecases/monitored_apps_planning.dart';
import '../../../domain/usecases/reconcile_settings.dart';

/// The apps selected for monitoring, persisted in the `monitored_apps` table.
///
/// On load it applies pending selection changes whose effective midnight has
/// passed, so a day rollover is recognised even when the midnight alarm was
/// missed. Changes made while a selection is already active are scheduled for
/// the next day (see `planMonitoredApps`).
class MonitoredAppsController extends AsyncNotifier<List<MonitoredApp>> {
  @override
  Future<List<MonitoredApp>> build() async {
    final repository = ref.watch(monitoredAppsRepositoryProvider);
    final settingsRepository = ref.watch(settingsRepositoryProvider);

    final apps = await repository.getAll();
    final settings = await settingsRepository.load();
    final reconciled = reconcileMonitoredApps(
      apps,
      pendingEffectiveAt: settings.pendingEffectiveAt,
      now: DateTime.now(),
    );
    if (!sameMonitoredApps(apps, reconciled)) {
      await repository.replaceAll(reconciled);
    }
    return reconciled;
  }

  /// First configuration: the selection applies immediately.
  Future<void> applySelectionNow(List<MonitoredApp> desired) async {
    await _requireUnlocked();
    final rows = applyMonitoredAppsNow(desired);
    await ref.read(monitoredAppsRepositoryProvider).replaceAll(rows);
    if (ref.mounted) state = AsyncData(rows);
  }

  /// Schedules selection changes for the next local midnight.
  Future<void> scheduleSelection(List<MonitoredApp> desired) async {
    await _requireUnlocked();
    final repository = ref.read(monitoredAppsRepositoryProvider);
    final current = state.value ?? await repository.getAll();
    final rows = planMonitoredApps(current: current, desired: desired);
    await repository.replaceAll(rows);
    if (ref.mounted) state = AsyncData(rows);
  }

  Future<void> _requireUnlocked() async {
    final settingsRepository = ref.read(settingsRepositoryProvider);
    await settingsRepository.reload();
    final settings = reconcileSettings(
      await settingsRepository.load(),
      DateTime.now(),
    );
    if (settings.isLocked) {
      throw StateError('The limit is locked until 00:00.');
    }
  }
}

final monitoredAppsControllerProvider =
    AsyncNotifierProvider<MonitoredAppsController, List<MonitoredApp>>(
      MonitoredAppsController.new,
    );

/// Package names that count towards the limit today.
///
/// Empty means "nothing selected yet" — Home then shows every app's usage but
/// no limit ring.
final enabledPackagesProvider = Provider<Set<String>>((ref) {
  final apps = ref.watch(monitoredAppsControllerProvider).value;
  if (apps == null) return const {};
  return {
    for (final app in apps)
      if (app.isEnabled) app.packageName,
  };
});

/// Package names that count after pending changes take effect.
final scheduledPackagesProvider = Provider<Set<String>>((ref) {
  final apps = ref.watch(monitoredAppsControllerProvider).value;
  if (apps == null) return const {};
  return scheduledPackages(apps);
});

/// True when the picker contains at least one change waiting for midnight.
final hasPendingAppChangesProvider = Provider<bool>((ref) {
  final apps = ref.watch(monitoredAppsControllerProvider).value;
  if (apps == null) return false;
  return hasPendingAppChange(apps);
});
