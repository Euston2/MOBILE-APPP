import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/utils/day_window.dart';
import '../../../domain/entities/usage_settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/usecases/reconcile_settings.dart';
import 'monitored_apps_controller.dart';

/// Loads and persists [UsageSettings].
///
/// Reconciles time-based transitions on every load, so a lock that expired
/// while the app was closed (or an alarm that never fired) is cleared as soon as
/// Dart reads the settings. The native service writes the lock fields directly
/// into the same prefs file; [reload] refreshes the Flutter cache after the app
/// resumes.
class SettingsController extends AsyncNotifier<UsageSettings> {
  Timer? _transitionTimer;

  @override
  Future<UsageSettings> build() async {
    ref.onDispose(() => _transitionTimer?.cancel());
    final repository = ref.watch(settingsRepositoryProvider);
    final settings = await _loadReconciled(repository);
    _scheduleTransition(settings);
    return settings;
  }

  /// Re-reads prefs (including native lock writes) and applies due transitions.
  Future<void> reload() async {
    final repository = ref.read(settingsRepositoryProvider);
    final settings = await _loadReconciled(repository, reload: true);
    if (!ref.mounted) return;
    state = AsyncData(settings);
    _scheduleTransition(settings);
    // A midnight transition can also apply pending app-selection changes.
    ref.invalidate(monitoredAppsControllerProvider);
  }

  /// First configuration (no limit/app set yet): apply immediately.
  Future<void> applyLimitNow(int seconds) => _update(
    (current) => current.copyWith(
      dailyLimitSeconds: seconds,
      clearPendingLimit: true,
      nextResetAt: nextLocalMidnight(DateTime.now()),
    ),
    requireUnlocked: true,
  );

  /// Schedules a limit for [effectiveAt] (the next local midnight).
  Future<void> scheduleLimit(int seconds, DateTime effectiveAt) => _update(
    (current) => current.copyWith(
      pendingLimitSeconds: seconds,
      pendingEffectiveAt: effectiveAt,
      nextResetAt: nextLocalMidnight(DateTime.now()),
    ),
    requireUnlocked: true,
  );

  Future<void> markOnboardingCompleted() =>
      _update((current) => current.copyWith(onboardingCompleted: true));

  Future<UsageSettings> _loadReconciled(
    SettingsRepository repository, {
    bool reload = false,
  }) async {
    if (reload) await repository.reload();
    final stored = await repository.load();
    final reconciled = reconcileSettings(stored, DateTime.now());
    if (reconciled != stored) {
      await repository.save(reconciled);
    }
    return reconciled;
  }

  Future<void> _update(
    UsageSettings Function(UsageSettings current) change, {
    bool requireUnlocked = false,
  }) async {
    final repository = ref.read(settingsRepositoryProvider);
    final current = await _loadReconciled(repository, reload: requireUnlocked);
    if (requireUnlocked && current.isLocked) {
      throw StateError('The limit is locked until 00:00.');
    }
    final updated = change(current);
    await repository.save(updated);
    if (!ref.mounted) return;
    state = AsyncData(updated);
    _scheduleTransition(updated);
  }

  /// Re-reads at the next lock/pending transition while the app stays open.
  ///
  /// The native service applies midnight on its own; this timer only keeps the
  /// Flutter UI (and the pushed blocking config) in step when the app happens to
  /// be open across 00:00.
  void _scheduleTransition(UsageSettings settings) {
    _transitionTimer?.cancel();

    final now = DateTime.now();
    final instants = <DateTime>[
      if (settings.pendingEffectiveAt != null &&
          settings.pendingEffectiveAt!.isAfter(now))
        settings.pendingEffectiveAt!,
      if (settings.isLocked && settings.nextResetAt.isAfter(now))
        settings.nextResetAt,
    ];
    if (instants.isEmpty) return;
    instants.sort();

    final next = instants.first;
    _transitionTimer = Timer(
      next.difference(now) + const Duration(seconds: 1),
      () async {
        if (!ref.mounted) return;
        try {
          await reload();
        } on Object {
          // Surfaced through the rebuilt provider (and the retry UI) instead of
          // crashing from a timer callback.
          if (ref.mounted) ref.invalidateSelf();
        }
      },
    );
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, UsageSettings>(
      SettingsController.new,
    );
