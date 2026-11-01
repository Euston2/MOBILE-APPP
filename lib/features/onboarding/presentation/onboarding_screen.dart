import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_resume_observer.dart';
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
          title: Text(isRoot ? 'Set up Lockout' : 'Permissions'),
          actions: [
            IconButton(
              tooltip: 'Re-check permissions',
              onPressed: refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: permissions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorRetryView(
            message: '$error',
            onRetry: () => ref.invalidate(permissionsControllerProvider),
          ),
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
                  'Usage access is required before anything can be counted.',
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
                label: const Text('Device-specific battery help'),
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
                'Lockout reads usage numbers on this device only. Nothing is '
                'sent anywhere.',
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

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock_clock_outlined,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A hard limit needs a few permissions',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: granted / PermissionKind.values.length,
              minHeight: 6,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 8),
            Text(
              '$granted of ${PermissionKind.values.length} granted',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
