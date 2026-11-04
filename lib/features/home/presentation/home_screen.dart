import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_names.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/utils/focus_window.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../domain/entities/app_usage.dart';
import '../../../domain/entities/installed_app.dart';
import '../../../domain/entities/permission_snapshot.dart';
import '../../../domain/entities/usage_settings.dart';
import '../../../domain/entities/usage_summary.dart';
import '../../../domain/usecases/evaluate_limit.dart';
import '../../../domain/usecases/focus_lock.dart';
import '../../blocking/presentation/blocking_controller.dart';
import '../../focus/presentation/focus_screen.dart';
import '../../history/presentation/archive_import_controller.dart';
import '../../history/presentation/history_screen.dart';
import '../../limits/presentation/monitored_apps_controller.dart';
import '../../limits/presentation/set_limits_screen.dart';
import '../../limits/presentation/settings_controller.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../onboarding/presentation/permission_copy.dart';
import '../../onboarding/presentation/permissions_controller.dart';
import '../../protection/presentation/protection_screen.dart';
import 'today_usage_controller.dart';
import 'widgets/usage_ring.dart';

/// Today's usage against the limit, plus the per-app breakdown.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(permissionsControllerProvider.notifier).refresh(),
      ref.read(todayUsageControllerProvider.notifier).refresh(),
      // The native service writes the lock fields into shared_preferences;
      // re-read them before repainting Home.
      ref.read(settingsControllerProvider.notifier).reload(),
    ]);
    if (!ref.context.mounted) return;
    // Reconcile pending changes (day rollover) and import any day archived
    // while the app was in the background.
    ref.invalidate(monitoredAppsControllerProvider);
    ref.invalidate(archiveImportProvider);
    // Re-push the saved limit even when its values did not change. The native
    // watcher may have been killed overnight; opening or refreshing Home should
    // restore enforcement without making the user save the settings again.
    ref.invalidate(blockingSyncProvider);
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

  Future<void> _openFocus(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const FocusScreen()));
  }

  Future<void> _openHistory(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const HistoryScreen()));
  }

  Future<void> _openProtection(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProtectionScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissions = ref.watch(permissionsControllerProvider).value;
    final settings = ref.watch(settingsControllerProvider).value;
    final monitored = ref.watch(monitoredAppsControllerProvider).value;
    final usage = ref.watch(todayUsageControllerProvider);
    final blocker = ref.watch(blockingSyncProvider);
    final installed =
        ref.watch(installedAppsProvider).value ?? const <InstalledApp>[];
    final labels = <String, String>{
      for (final app in installed)
        app.packageName: friendlyAppName(app.packageName, app.displayName),
      for (final app in monitored ?? const [])
        app.packageName: friendlyAppName(app.packageName, app.displayName),
    };
    final missing = permissions?.missing ?? const <PermissionKind>[];
    final monitoredCount = monitored?.where((app) => app.isEnabled).length ?? 0;
    final locked = settings?.isLocked ?? false;
    final nextResetAt = settings?.nextResetAt;
    final pendingApps = ref.watch(hasPendingAppChangesProvider);
    final pendingLimit = settings?.pendingLimitSeconds;
    final hasPendingChange = !locked && (pendingLimit != null || pendingApps);
    final scheduledLimit = pendingLimit ?? settings?.dailyLimitSeconds ?? 0;
    final scheduledAppCount =
        monitored?.where((app) => app.scheduledEnabled).length ?? 0;

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
            tooltip: 'History',
            onPressed: () => _openHistory(context),
            icon: const Icon(Icons.bar_chart),
          ),
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
            tooltip: 'Access and setup',
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
              if (blocker.hasError) ...[
                _BlockerBanner(
                  onRetry: () => ref.invalidate(blockingSyncProvider),
                ),
                const SizedBox(height: 12),
              ],
              if (hasPendingChange) ...[
                _ScheduledChangeBanner(
                  limitSeconds: scheduledLimit,
                  appCount: scheduledAppCount,
                ),
                const SizedBox(height: 12),
              ],
              _LimitCard(
                status: status,
                summary: summary,
                locked: locked,
                nextResetAt: nextResetAt,
                onConfigure: () => _openLimits(context),
              ),
              const SizedBox(height: 16),
              _FocusCard(settings: settings, onTap: () => _openFocus(context)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text('Apps', style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    monitoredCount == 0
                        ? 'all apps'
                        : '$monitoredCount ${monitoredCount == 1 ? 'app' : 'apps'}',
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
                error: (error, _) {
                  debugPrint('Today usage load failed: $error');
                  return ErrorRetryView(
                    title: "Couldn't load today's usage",
                    message:
                        'Your app time is not available right now. '
                        'Please try again.',
                    onRetry: () => ref
                        .read(todayUsageControllerProvider.notifier)
                        .refresh(),
                  );
                },
                data: (summary) => summary.isEmpty
                    ? const _EmptyUsageCard()
                    : Column(
                        children: [
                          for (final app in summary.perApp)
                            _AppUsageRow(
                              usage: app,
                              label:
                                  labels[app.packageName] ??
                                  friendlyAppName(app.packageName, null),
                              fraction: summary.topApp == null
                                  ? 0
                                  : app.seconds / summary.topApp!.seconds,
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.health_and_safety_outlined),
                  title: const Text('Protection check'),
                  subtitle: const Text(
                    'Battery help, access and recent activity',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openProtection(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Updates every few seconds while Lockout is open. '
                'Your time resets at midnight.',
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
    required this.locked,
    required this.nextResetAt,
    required this.onConfigure,
  });

  final LimitStatus status;
  final UsageSummary? summary;
  final bool locked;
  final DateTime? nextResetAt;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reached = status.isReached;
    final appCount = summary?.perApp.length ?? 0;
    final resetAt = nextResetAt;

    final String statusLine;
    if (locked) {
      statusLine = 'Locked until midnight';
    } else if (!status.hasLimit) {
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
                color: reached || locked
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
                  ? 'Since midnight'
                  : 'Since midnight · $appCount '
                        '${appCount == 1 ? 'app' : 'apps'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (locked && resetAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Resets in '
                '${formatCountdown(resetAt.difference(DateTime.now()))}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (locked || reached) ...[
              const SizedBox(height: 8),
              Text(
                'Your chosen apps are blocked until midnight.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (!status.hasLimit)
              FilledButton.tonal(
                onPressed: onConfigure,
                child: const Text('Set limit & apps'),
              )
            else
              TextButton(
                onPressed: onConfigure,
                child: Text(locked ? 'Locked' : 'Edit limit & apps'),
              ),
          ],
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.settings, required this.onTap});

  final UsageSettings? settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final current = settings;
    final studyActive = current != null && isStudyLockActive(current, now);
    final overnightActive =
        current != null &&
        current.overnightLockEnabled &&
        isOvernightLockWindow(now);
    final activeUntil = current == null
        ? null
        : activeFocusLockEnd(current, now);
    final active = studyActive || overnightActive;

    final String title;
    final String subtitle;
    if (studyActive) {
      title = 'Study lock on';
      subtitle =
          'Until ${formatClockTime(activeUntil!)}. Selected apps are blocked.';
    } else if (overnightActive) {
      title = 'Overnight lock on';
      subtitle =
          'Until ${formatClockTime(overnightLockEndFor(now))}. '
          'Selected apps are blocked.';
    } else if (current?.overnightLockEnabled ?? false) {
      title = 'Overnight lock on';
      subtitle = 'Every night, 12:00 AM to 8:00 AM.';
    } else {
      title = 'Focus locks';
      subtitle = 'Overnight 12-8 AM and one-off study sessions.';
    }

    return Card(
      color: active ? theme.colorScheme.secondaryContainer : null,
      child: ListTile(
        leading: Icon(
          active ? Icons.lock_clock_outlined : Icons.timer_outlined,
          color: active ? theme.colorScheme.onSecondaryContainer : null,
        ),
        title: Text(
          title,
          style: active
              ? theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                )
              : null,
        ),
        subtitle: Text(
          subtitle,
          style: active
              ? theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                )
              : null,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: active ? theme.colorScheme.onSecondaryContainer : null,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ScheduledChangeBanner extends StatelessWidget {
  const _ScheduledChangeBanner({
    required this.limitSeconds,
    required this.appCount,
  });

  final int limitSeconds;
  final int appCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.schedule_outlined,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New settings start at midnight',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    'Tomorrow: ${formatDuration(limitSeconds)} · '
                    '$appCount ${appCount == 1 ? 'app' : 'apps'}. '
                    "Today's settings stay in force until then.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockerBanner extends StatelessWidget {
  const _BlockerBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(
              Icons.gpp_maybe_outlined,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Protection couldn't start",
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  Text(
                    'Allow notifications and display over other apps, then '
                    'try again.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
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
                        ? '1 setting needs attention'
                        : '${missing.length} settings need attention',
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
            TextButton(onPressed: onFix, child: const Text('Review')),
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
