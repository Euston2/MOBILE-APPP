import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/utils/day_window.dart';
import '../../../domain/entities/usage_settings.dart';

/// Loads and persists [UsageSettings].
///
/// Stage 2 only edits the limit and the onboarding flag; Stage 4 adds lock
/// transitions (lock on limit, clear at midnight) through the same controller.
class SettingsController extends AsyncNotifier<UsageSettings> {
  @override
  Future<UsageSettings> build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> saveLimit(int seconds) {
    final now = DateTime.now();
    return _update(
      (current) => current.copyWith(
        dailyLimitSeconds: seconds,
        nextResetAt: nextLocalMidnight(now),
      ),
    );
  }

  Future<void> markOnboardingCompleted() =>
      _update((current) => current.copyWith(onboardingCompleted: true));

  Future<void> _update(
    UsageSettings Function(UsageSettings current) change,
  ) async {
    final repository = ref.read(settingsRepositoryProvider);
    final current = state.value ?? await repository.load();
    final updated = change(current);
    await repository.save(updated);
    if (ref.mounted) state = AsyncData(updated);
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, UsageSettings>(
      SettingsController.new,
    );
