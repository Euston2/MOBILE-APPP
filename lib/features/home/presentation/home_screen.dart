import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../domain/entities/app_usage.dart';
import '../../../domain/entities/installed_app.dart';
import '../../../domain/entities/permission_snapshot.dart';
import '../../../domain/entities/usage_summary.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../onboarding/presentation/permission_copy.dart';
import '../../onboarding/presentation/permissions_controller.dart';
import 'today_usage_controller.dart';

/// Today's counter and per-app breakdown.
///
/// Stage 2 adds the limit ring and lock state on top of this screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(permissionsControllerProvider.notifier).refresh(),
      ref.read(todayUsageControllerProvider.notifier).refresh(),
    ]);
  }

  void _openPermissions(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissions = ref.watch(permissionsControllerProvider).value;
    final usage = ref.watch(todayUsageControllerProvider);
    final installed =
        ref.watch(installedAppsProvider).value ?? const <InstalledApp>[];
    final labels = <String, String>{
      for (final app in installed) app.packageName: app.displayName,
    };
    final missing = permissions?.missing ?? const <PermissionKind>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Permissions and setup',
            onPressed: () => _openPermissions(context),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: AppResumeObserver(
        onResume: () => _refresh(ref),
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (missing.isNotEmpty) ...[
                _PermissionBanner(
                  missing: missing,
                  onFix: () => _openPermissions(context),
                ),
                const SizedBox(height: 12),
              ],
              _TotalCard(summary: usage.value),
              const SizedBox(height: 24),
              Text('Apps', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              usage.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ErrorRetryView(
                  message: '$error',
                  onRetry: () =>
                      ref.read(todayUsageControllerProvider.notifier).refresh(),
                ),
                data: (summary) => summary.isEmpty
                    ? const _EmptyUsageCard()
                    : Column(
                        children: [
                          for (final app in summary.perApp)
                            _AppUsageRow(
                              usage: app,
                              label: labels[app.packageName] ?? app.packageName,
                              fraction: summary.topApp == null
                                  ? 0
                                  : app.seconds / summary.topApp!.seconds,
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                'Updates every few seconds while Lockout is open.',
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

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.missing, required this.onFix});

  final List<PermissionKind> missing;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final names = missing
        .map((kind) => permissionCopy(kind).shortLabel)
        .join(', ');

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    missing.length == 1
                        ? '1 permission missing'
                        : '${missing.length} permissions missing',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  Text(
                    names,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onFix, child: const Text('Fix')),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.summary});

  final UsageSummary? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seconds = summary?.totalSeconds ?? 0;
    final appCount = summary?.perApp.length ?? 0;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Time used today',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              summary == null ? '—' : formatDuration(seconds),
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              summary == null
                  ? 'Reading usage…'
                  : appCount == 0
                  ? 'Since 00:00'
                  : 'Since 00:00 · $appCount ${appCount == 1 ? 'app' : 'apps'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppUsageRow extends StatelessWidget {
  const _AppUsageRow({
    required this.usage,
    required this.label,
    required this.fraction,
  });

  final AppUsage usage;
  final String label;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = fraction.isFinite ? fraction.clamp(0.02, 1.0) : 0.02;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatDuration(usage.seconds),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyUsageCard extends StatelessWidget {
  const _EmptyUsageCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.hourglass_empty,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No usage recorded yet today. Use your phone normally and pull '
                'down to refresh.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
