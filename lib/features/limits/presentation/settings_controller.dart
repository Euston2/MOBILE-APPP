import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/utils/day_window.dart';
import '../../../core/utils/focus_window.dart';
import '../../../domain/entities/usage_settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/usecases/focus_lock.dart';
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

  /// Enables or disables the fixed 00:00-08:00 overnight lock.
  ///
  /// Once the window has started the lock cannot be turned off until 08:00.
  /// This is a product rule, not just a disabled switch: the controller also
  /// rejects the change so another caller cannot bypass it.
  Future<void> setOvernightLock(bool enabled) async {
    final now = DateTime.now();
    if (enabled && ref.read(enabledPackagesProvider).isEmpty) {
      throw StateError('Choose at least one app first.');
    }
    await _update((current) {
      if (!enabled && !canTurnOffOvernightLock(current, now)) {
        throw StateError('Overnight lock cannot be turned off until 08:00.');
      }
      return current.copyWith(overnightLockEnabled: enabled);
    });
  }

  /// Starts a one-off study lock for [minutes] from now.
  ///
  /// There is no matching stop method while the session is running; the
  /// session expires on its own and [reconcileSettings] clears it then.
  Future<void> startStudySession(int minutes) async {
    if (minutes < 5 || minutes > 8 * 60) {
      throw ArgumentError.value(minutes, 'minutes', 'must be 5-480');
    }
    if (ref.read(enabledPackagesProvider).isEmpty) {
      throw StateError('Choose at least one app first.');
    }

    final now = DateTime.now();
    final endsAt = now.add(Duration(minutes: minutes));
    await _update((current) {
      if (isStudyLockActive(current, now)) {
        throw StateError('A study lock is already running.');
      }
      return current.copyWith(studyEndsAt: endsAt, studyLengthMinutes: minutes);
    });
  }

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
    if (requireUnlocked &&
        (current.isLocked || isFocusLockActive(current, DateTime.now()))) {
      throw StateError('The limit is locked until the current block ends.');
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
      if (settings.studyEndsAt != null && settings.studyEndsAt!.isAfter(now))
        settings.studyEndsAt!,
      if (settings.overnightLockEnabled)
        now.isBefore(overnightLockEndFor(now))
            ? overnightLockEndFor(now)
            : nextLocalMidnight(now),
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
