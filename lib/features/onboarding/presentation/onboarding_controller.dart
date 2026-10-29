import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the user finished (or skipped) the setup flow.
///
/// Stage 1 keeps this in memory only; Stage 2 persists it with the other
/// settings so a fully set-up device goes straight to Home.
class OnboardingCompleted extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() => state = true;

  void reset() => state = false;
}

final onboardingCompletedProvider = NotifierProvider<OnboardingCompleted, bool>(
  OnboardingCompleted.new,
);
