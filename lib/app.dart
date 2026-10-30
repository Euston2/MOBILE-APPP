import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_resume_observer.dart';
import 'features/blocking/presentation/blocking_controller.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/limits/presentation/settings_controller.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/onboarding/presentation/permissions_controller.dart';

/// Root widget of the Lockout application.
class LockoutApp extends StatelessWidget {
  const LockoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _AppGate(),
    );
  }
}

/// Decides between setup and Home.
///
/// Home is shown when every permission is granted, or when the user has
/// finished (or skipped) setup on an earlier launch — that flag is persisted in
/// settings, so a configured device boots straight into Home.
class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsControllerProvider);
    final settings = ref.watch(settingsControllerProvider);

    // Side effect: push the latest limit/app selection to the native watcher.
    // Watched here (not in a screen) so it happens on every change, including
    // the initial load, no matter which route is visible.
    ref.watch(blockingSyncProvider);

    if (settings.hasError) {
      return Scaffold(
        body: ErrorRetryView(
          message: '${settings.error}',
          onRetry: () => ref.invalidate(settingsControllerProvider),
        ),
      );
    }

    return permissions.when(
      loading: () => const _StartupScreen(),
      error: (error, _) => Scaffold(
        body: ErrorRetryView(
          message: '$error',
          onRetry: () => ref.invalidate(permissionsControllerProvider),
        ),
      ),
      data: (snapshot) {
        final current = settings.value;
        if (current == null) return const _StartupScreen();
        final ready = current.onboardingCompleted || snapshot.allGranted;
        return ready
            ? const HomeScreen()
            : const OnboardingScreen(isRoot: true);
      },
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_clock_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(AppConstants.appName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
