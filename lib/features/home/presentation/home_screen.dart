import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_names.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/utils/focus_window.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../core/widgets/lockout_ui.dart';
import '../../../domain/entities/app_usage.dart';
import '../../../domain/entities/installed_app.dart';
import '../../../domain/entities/permission_snapshot.dart';
import '../../../domain/entities/usage_settings.dart';
import '../../../domain/entities/usage_summary.dart';
import '../../../domain/usecases/evaluate_limit.dart';
import '../../../domain/usecases/focus_lock.dart';
import '../../../domain/usecases/study_timer.dart';
import '../../blocking/presentation/blocking_controller.dart';
import '../../focus/presentation/focus_screen.dart';
import '../../focus/presentation/study_timer_screen.dart';
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

  Future<void> _openStudyTimer(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const StudyTimerScreen()));
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
    final statusLabel = locked
        ? 'Locked'
        : status.isReached
        ? 'Limit hit'
        : status.hasLimit
        ? 'Strict mode'
        : 'Set up';
    final statusAccent = locked || status.isReached
        ? LockoutPalette.coral
        : status.hasLimit
        ? LockoutPalette.mint
        : LockoutPalette.amber;

    return Scaffold(
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
            Row(
              children: [
                Text('Today', style: theme.textTheme.headlineSmall),
                const SizedBox(width: 10),
                LockoutPill(
                  statusLabel,
                  color: statusAccent,
                  icon: locked
                      ? Icons.lock_outline
                      : status.hasLimit
                      ? Icons.shield_outlined
                      : Icons.add_circle_outline,
                ),
              ],
            ),
          ],
        ),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: LockoutMetricCard(
                      label: 'Remaining',
                      value: status.hasLimit
                          ? formatDuration(status.remainingSeconds)
                          : '—',
                      caption: status.hasLimit
                          ? 'before hard lock'
                          : 'no limit configured',
                      icon: Icons.shield_outlined,
                      accent: statusAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LockoutMetricCard(
                      label: 'Daily limit',
                      value: status.hasLimit
                          ? formatDuration(status.limitSeconds)
                          : 'Not set',
                      caption: 'resets at midnight',
                      icon: Icons.tune,
                      accent: LockoutPalette.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StudyTimerCard(
                settings: settings,
                onTap: () => _openStudyTimer(context),
              ),
              const SizedBox(height: 10),
              _FocusCard(settings: settings, onTap: () => _openFocus(context)),
              const SizedBox(height: 10),
              LockoutCardSurface(
                onTap: () => _openLimits(context),
                padding: const EdgeInsets.all(16),
                borderColor: LockoutPalette.mint.withValues(alpha: 0.2),
                child: Row(
                  children: [
                    const LockoutIconBadge(Icons.gavel_outlined, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hard lock commitment',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'A lock cannot be relaxed from inside a blocked '
                            'app. Your rules reset at midnight.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LockoutSectionLabel(
                'Monitored social apps',
                trailing: Text(
                  monitoredCount == 0
                      ? 'all apps'
                      : '$monitoredCount ${monitoredCount == 1 ? 'app' : 'apps'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Combined time counts against one daily allowance.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
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
              LockoutCardSurface(
                onTap: () => _openProtection(context),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    const LockoutIconBadge(
                      Icons.health_and_safety_outlined,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Protection check',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            'Battery help, access and recent activity',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
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

    final accent = reached || locked
        ? LockoutPalette.coral
        : LockoutPalette.mint;

    return LockoutCardSurface(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      borderColor: accent.withValues(alpha: 0.24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.14),
          LockoutPalette.surface,
          LockoutPalette.surface,
        ],
        stops: const [0, 0.48, 1],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: LockoutSectionLabel('Daily budget')),
              LockoutPill(
                locked
                    ? 'Sealed'
                    : reached
                    ? 'Limit hit'
                    : status.hasLimit
                    ? 'Active'
                    : 'Not set',
                color: accent,
                icon: locked
                    ? Icons.lock_outline
                    : status.hasLimit
                    ? Icons.bolt
                    : Icons.tune,
              ),
            ],
          ),
          const SizedBox(height: 14),
          UsageRing(status: status),
          const SizedBox(height: 14),
          Text(
            statusLine,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: reached || locked ? accent : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
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
              style: theme.textTheme.bodySmall?.copyWith(color: accent),
            ),
          ],
          if (locked || reached) ...[
            const SizedBox(height: 8),
            Text(
              'Your chosen apps are blocked until midnight.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: accent),
            ),
          ],
          const SizedBox(height: 14),
          if (!status.hasLimit)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onConfigure,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Set limit & apps'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: locked ? null : onConfigure,
                icon: Icon(locked ? Icons.lock_outline : Icons.tune, size: 18),
                label: Text(locked ? 'Locked' : 'Edit limit & apps'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudyTimerCard extends StatelessWidget {
  const _StudyTimerCard({required this.settings, required this.onTap});

  final UsageSettings? settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final current = settings;
    final goalSeconds = (current?.focusGoalMinutes ?? 0) * 60;
    final todaySeconds = current == null
        ? 0
        : focusSecondsForToday(current, now);
    final blockActive = current != null && isFocusGoalBlockActive(current, now);
    final running = current != null && isFocusSessionRunning(current, now);
    final paused = current != null && isFocusSessionPaused(current, now);

    final String title;
    final String subtitle;
    if (blockActive) {
      title = 'Focus goal missed';
      subtitle =
          '${formatDuration(todaySeconds)} of '
          '${formatDuration(goalSeconds)} today · apps blocked until midnight';
    } else if (running) {
      title = 'Focusing now';
      subtitle = goalSeconds > 0
          ? '${formatDuration(todaySeconds)} of '
                '${formatDuration(goalSeconds)} today'
          : '${formatDuration(todaySeconds)} focused today';
    } else if (paused) {
      title = 'Focus timer paused';
      subtitle = '${formatDuration(todaySeconds)} focused today';
    } else if (goalSeconds > 0) {
      title = 'Study timer';
      subtitle =
          '${formatDuration(todaySeconds)} of '
          '${formatDuration(goalSeconds)} today';
    } else {
      title = 'Study timer';
      subtitle = 'Set a daily goal or start a focus session.';
    }

    final accent = blockActive
        ? LockoutPalette.coral
        : running
        ? LockoutPalette.mint
        : LockoutPalette.amber;

    return LockoutCardSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      borderColor: accent.withValues(alpha: blockActive ? 0.34 : 0.16),
      child: Row(
        children: [
          LockoutIconBadge(
            blockActive
                ? Icons.lock_clock_outlined
                : running
                ? Icons.timelapse
                : Icons.timer_outlined,
            color: accent,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: blockActive ? accent : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: blockActive ? accent : null,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
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
    final focusGoalActive =
        current != null && isFocusGoalBlockActive(current, now);
    final activeUntil = current == null
        ? null
        : activeFocusLockEnd(current, now);
    final active = studyActive || overnightActive || focusGoalActive;

    final String title;
    final String subtitle;
    if (studyActive) {
      title = 'Study lock on';
      subtitle =
          'Until ${formatClockTime(activeUntil!)}. Selected apps are blocked.';
    } else if (focusGoalActive) {
      title = 'Focus goal missed';
      subtitle =
          'Selected apps are blocked until midnight. Finish a focus session '
          'to unlock them early.';
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

    final accent = active ? LockoutPalette.amber : LockoutPalette.mint;

    return LockoutCardSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      borderColor: accent.withValues(alpha: active ? 0.3 : 0.14),
      child: Row(
        children: [
          LockoutIconBadge(
            active ? Icons.lock_clock_outlined : Icons.nightlight_outlined,
            color: accent,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: active ? accent : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: active ? accent : null,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
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
    final initial = label.trim().isEmpty
        ? '?'
        : label.trim().substring(0, 1).toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LockoutCardSurface(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: LockoutPalette.mintDeep,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: LockoutPalette.mint.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                initial,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: LockoutPalette.mint,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatDuration(usage.seconds),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: LockoutPalette.mint,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LockoutProgressBar(value: value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyUsageCard extends StatelessWidget {
  const _EmptyUsageCard();

  @override
  Widget build(BuildContext context) {
    return const LockoutEmptyState(
      icon: Icons.hourglass_empty,
      title: 'A clear day so far',
      message:
          'No usage recorded yet today. Use your phone normally and pull '
          'down to refresh.',
    );
  }
}
