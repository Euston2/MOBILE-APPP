import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../core/widgets/lockout_ui.dart';
import '../../../domain/entities/permission_snapshot.dart';
import '../../limits/presentation/settings_controller.dart';
import '../../protection/presentation/protection_screen.dart';
import 'permissions_controller.dart';
import 'widgets/permission_tile.dart';

/// Guided setup for the four special permissions.
///
/// [isRoot] is true when the gate shows this screen as the app entry point;
/// when it is pushed from Home, "Continue" simply pops.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({this.isRoot = false, super.key});

  final bool isRoot;

  void _finish(BuildContext context, WidgetRef ref) {
    if (isRoot) {
      unawaited(
        ref.read(settingsControllerProvider.notifier).markOnboardingCompleted(),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissions = ref.watch(permissionsControllerProvider);

    Future<void> refresh() =>
        ref.read(permissionsControllerProvider.notifier).refresh();

    return AppResumeObserver(
      onResume: refresh,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOCKOUT',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: LockoutPalette.mint,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isRoot ? 'Set up Lockout' : 'Allow access',
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Check again',
              onPressed: refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: permissions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            debugPrint('Permission check failed: $error');
            return ErrorRetryView(
              title: "Couldn't check access",
              message: 'Please try again.',
              onRetry: () => ref.invalidate(permissionsControllerProvider),
            );
          },
          data: (snapshot) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _IntroCard(snapshot: snapshot),
              const SizedBox(height: 16),
              for (final kind in PermissionKind.values)
                PermissionTile(
                  kind: kind,
                  isGranted: snapshot.isGranted(kind),
                  onOpenSettings: () => ref
                      .read(permissionsControllerProvider.notifier)
                      .openSettings(kind),
                ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: snapshot.canTrack
                    ? () => _finish(context, ref)
                    : null,
                child: Text(
                  snapshot.allGranted
                      ? 'Continue'
                      : 'Continue with limited protection',
                ),
              ),
              if (!snapshot.canTrack) ...[
                const SizedBox(height: 8),
                Text(
                  'Allow app activity access so Lockout can count your time.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProtectionScreen(),
                  ),
                ),
                icon: const Icon(Icons.battery_saver_outlined),
                label: const Text('Battery help for your phone'),
              ),
              if (isRoot) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => unawaited(
                    ref
                        .read(settingsControllerProvider.notifier)
                        .markOnboardingCompleted(),
                  ),
                  child: const Text('Skip for now'),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Lockout counts app time only on this phone. Nothing is sent '
                'anywhere.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.snapshot});

  final PermissionSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final granted = snapshot.granted.length;

    return LockoutCardSurface(
      padding: const EdgeInsets.all(18),
      borderColor: LockoutPalette.mint.withValues(alpha: 0.2),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          LockoutPalette.mint.withValues(alpha: 0.08),
          LockoutPalette.surface,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LockoutIconBadge(Icons.lock_clock_outlined, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'A few settings keep Lockout running',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              LockoutPill(
                '$granted/${PermissionKind.values.length}',
                color: granted == PermissionKind.values.length
                    ? LockoutPalette.mint
                    : LockoutPalette.amber,
              ),
            ],
          ),
          const SizedBox(height: 14),
          LockoutProgressBar(
            value: granted / PermissionKind.values.length,
            height: 7,
          ),
          const SizedBox(height: 8),
          Text(
            '$granted of ${PermissionKind.values.length} ready',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
