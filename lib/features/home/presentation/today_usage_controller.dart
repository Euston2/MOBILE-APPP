import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/utils/day_window.dart';
import '../../../domain/entities/installed_app.dart';
import '../../../domain/entities/usage_summary.dart';
import '../../../domain/repositories/usage_repository.dart';
import '../../limits/presentation/monitored_apps_controller.dart';

/// Today's combined usage, refreshed on a timer while Home is visible.
///
/// Once apps are selected, only their usage is returned. Polling (rather than
/// an EventChannel) is enough until the foreground service exists in Stage 3.
class TodayUsageController extends AsyncNotifier<UsageSummary> {
  Timer? _timer;
  bool _disposed = false;
  Set<String>? _packages;

  @override
  Future<UsageSummary> build() async {
    _timer?.cancel();
    _disposed = false;

    final repository = ref.watch(usageRepositoryProvider);
    final interval = ref.watch(usagePollIntervalProvider);
    final enabled = ref.watch(enabledPackagesProvider);
    _packages = enabled.isEmpty ? null : enabled;

    _timer = Timer.periodic(interval, (_) => _poll(repository));
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
      _timer = null;
    });

    return _load(repository);
  }

  Future<UsageSummary> _load(UsageRepository repository) {
    final now = DateTime.now();
    return repository.getUsageForWindow(
      start: startOfLocalDay(now),
      end: now,
      monitoredPackages: _packages,
    );
  }

  /// Background poll: never flashes a loading state and keeps the last good
  /// snapshot if the platform hiccups.
  Future<void> _poll(UsageRepository repository) async {
    if (_disposed) return;
    try {
      final summary = await _load(repository);
      if (!_disposed) state = AsyncData(summary);
    } on Object {
      // Ignore transient read failures; manual refresh surfaces the error.
    }
  }

  Future<void> refresh() async {
    final repository = ref.read(usageRepositoryProvider);
    state = await AsyncValue.guard(() => _load(repository));
  }
}

final todayUsageControllerProvider =
    AsyncNotifierProvider<TodayUsageController, UsageSummary>(
      TodayUsageController.new,
    );

/// Installed apps, used to turn package names into human labels.
final installedAppsProvider = FutureProvider<List<InstalledApp>>(
  (ref) => ref.watch(usageRepositoryProvider).getInstalledApps(),
);
