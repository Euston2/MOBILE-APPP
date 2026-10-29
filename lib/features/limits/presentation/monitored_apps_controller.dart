import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../domain/entities/monitored_app.dart';

/// The apps selected for monitoring, persisted in the `monitored_apps` table.
class MonitoredAppsController extends AsyncNotifier<List<MonitoredApp>> {
  @override
  Future<List<MonitoredApp>> build() =>
      ref.watch(monitoredAppsRepositoryProvider).getAll();

  Future<void> replaceAll(List<MonitoredApp> apps) async {
    await ref.read(monitoredAppsRepositoryProvider).replaceAll(apps);
    if (ref.mounted) state = AsyncData(List.unmodifiable(apps));
  }
}

final monitoredAppsControllerProvider =
    AsyncNotifierProvider<MonitoredAppsController, List<MonitoredApp>>(
      MonitoredAppsController.new,
    );

/// Package names that count towards the limit.
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
