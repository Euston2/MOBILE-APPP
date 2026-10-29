import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../domain/entities/app_usage.dart';
import '../../../domain/entities/installed_app.dart';
import '../../../domain/entities/permission_snapshot.dart';
import '../../../domain/entities/usage_summary.dart';
import '../../../domain/usecases/evaluate_limit.dart';
import '../../limits/presentation/monitored_apps_controller.dart';
import '../../limits/presentation/set_limits_screen.dart';
import '../../limits/presentation/settings_controller.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../onboarding/presentation/permission_copy.dart';
import '../../onboarding/presentation/permissions_controller.dart';
import 'today_usage_controller.dart';
import 'widgets/usage_ring.dart';

/// Today's usage against the limit, plus the per-app breakdown.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(permissionsControllerProvider.notifier).refresh(),
      ref.read(todayUsageControllerProvider.notifier).refresh(),
    ]);
  }

  Future<void> _openPermissions(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()));
  }

  Future<void> _openLimits(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SetLimitsScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissions = ref.watch(permissionsControllerProvider).value;
    final settings = ref.watch(settingsControllerProvider).value;
    final monitored = ref.watch(monitoredAppsControllerProvider).value;
    final usage = ref.watch(todayUsageControllerProvider);
    final installed =
        ref.watch(installedAppsProvider).value ?? const <InstalledApp>[];
    final labels = <String, String>{
      for (final app in installed) app.packageName: app.displayName,
      for (final app in monitored ?? const []) app.packageName: app.displayName,
    };
    final missing = permissions?.missing ?? const <PermissionKind>[];
    final monitoredCount = monitored?.where((app) => app.isEnabled).length ?? 0;

    final summary = usage.value;
    final status = evaluateLimit(
      usedSeconds: summary?.totalSeconds ?? 0,
      limitSeconds: settings?.dailyLimitSeconds ?? 0,
    );

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
            tooltip: 'Limit and apps',
            onPressed: () => _openLimits(context),
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Permissions and setup',
            onPressed: () => _openPermissions(context),
            icon: const Icon(Icons.shield_outlined),
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
              _LimitCard(
                status: status,
                summary: summary,
                onConfigure: () => _openLimits(context),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text('Apps', style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    monitoredCount == 0
                        ? 'all apps'
                        : '$monitoredCount monitored',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
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
                'Updates every few seconds while Lockout is open. '
                'The counter resets at 00:00.',
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

class _LimitCard extends StatelessWidget {
  const _LimitCard({
    required this.status,
    required this.summary,
    required this.onConfigure,
  });

  final LimitStatus status;
  final UsageSummary? summary;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reached = status.isReached;
    final appCount = summary?.perApp.length ?? 0;

    final String statusLine;
    if (!status.hasLimit) {
      statusLine = 'No daily limit set yet';
    } else if (reached) {
      final over = status.overSeconds;
      statusLine = over > 0
          ? 'Limit reached · ${formatDuration(over)} over'
          : 'Limit reached';
    } else {
      statusLine = '${formatDuration(status.remainingSeconds)} left today';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          children: [
            UsageRing(status: status),
            const SizedBox(height: 16),
            Text(
              statusLine,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: reached
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              summary == null
                  ? 'Reading usage…'
                  : appCount == 0
                  ? 'Since 00:00'
                  : 'Since 00:00 · $appCount ${appCount == 1 ? 'app' : 'apps'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (!status.hasLimit)
              FilledButton.tonal(
                onPressed: onConfigure,
                child: const Text('Set limit & apps'),
              )
            else
              TextButton(
                onPressed: onConfigure,
                child: const Text('Edit limit & apps'),
              ),
          ],
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
