import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../domain/entities/device_diagnostics.dart';
import '../../../domain/entities/permission_snapshot.dart';
import '../../onboarding/presentation/permissions_controller.dart';
import 'diagnostics_controller.dart';
import 'diagnostics_report.dart';
import 'oem_guidance.dart';

/// One place to verify that Lockout can survive this phone.
///
/// It combines the four essential special accesses, exact-alarm precision, the
/// OEM autostart/battery instructions, the enforcement state and the bounded
/// native event log. Everything is read-only; the buttons open system screens.
class ProtectionScreen extends ConsumerWidget {
  const ProtectionScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(diagnosticsControllerProvider.notifier).refresh(),
      ref.read(permissionsControllerProvider.notifier).refresh(),
    ]);
  }

  Future<void> _copyReport(
    BuildContext context,
    DeviceDiagnostics diagnostics,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: buildDiagnosticsReport(diagnostics)),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostics copied to the clipboard.')),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open that screen: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostics = ref.watch(diagnosticsControllerProvider);

    return AppResumeObserver(
      onResume: () => unawaited(_refresh(ref)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Protection check'),
          actions: [
            IconButton(
              tooltip: 'Refresh status',
              onPressed: () => _refresh(ref),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: diagnostics.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: ErrorRetryView(
              message: '$error',
              onRetry: () => ref.invalidate(diagnosticsControllerProvider),
            ),
          ),
          data: (snapshot) {
            final guidance = oemGuidanceFor(
              manufacturer: snapshot.manufacturer,
              brand: snapshot.brand,
            );
            return RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _StatusCard(diagnostics: snapshot),
                  const SizedBox(height: 20),
                  Text(
                    'Essential checks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _CheckTile(
                    title: 'Usage access',
                    detail: snapshot.usageAccess
                        ? 'Lockout can read per-app foreground time.'
                        : 'Required to count usage and enforce the limit.',
                    passed: snapshot.usageAccess,
                    fixLabel: 'Open',
                    onFix: () => ref
                        .read(permissionsControllerProvider.notifier)
                        .openSettings(PermissionKind.usageAccess),
                  ),
                  _CheckTile(
                    title: 'Display over other apps',
                    detail: snapshot.overlay
                        ? 'The block screen can cover a monitored app.'
                        : 'Required for the block screen fallback.',
                    passed: snapshot.overlay,
                    fixLabel: 'Open',
                    onFix: () => ref
                        .read(permissionsControllerProvider.notifier)
                        .openSettings(PermissionKind.overlay),
                  ),
                  _CheckTile(
                    title: 'Notifications',
                    detail: snapshot.notifications
                        ? 'The foreground watcher can stay visible.'
                        : 'Required so Android keeps the watcher running.',
                    passed: snapshot.notifications,
                    fixLabel: 'Open',
                    onFix: () => ref
                        .read(permissionsControllerProvider.notifier)
                        .openSettings(PermissionKind.notifications),
                  ),
                  _CheckTile(
                    title: 'Battery optimisation',
                    detail: snapshot.batteryOptimizationIgnored
                        ? 'Battery savers are not allowed to kill the watcher.'
                        : 'Allow Lockout to run without battery restrictions.',
                    passed: snapshot.batteryOptimizationIgnored,
                    fixLabel: 'Open',
                    onFix: () => ref
                        .read(permissionsControllerProvider.notifier)
                        .openSettings(PermissionKind.batteryOptimization),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reset precision',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _CheckTile(
                    title: 'Exact alarms',
                    detail: snapshot.exactAlarmsAllowed
                        ? 'The 00:00 reset can fire on time.'
                        : 'Optional: Android may delay the reset, but the '
                              'next check still recovers it.',
                    passed: snapshot.exactAlarmsAllowed,
                    isOptional: true,
                    fixLabel: 'Open',
                    onFix: () => ref
                        .read(diagnosticsControllerProvider.notifier)
                        .openExactAlarmSettings(),
                  ),
                  const SizedBox(height: 20),
                  _OemCard(
                    guidance: guidance,
                    onOpenAutostart: () => _run(
                      context,
                      () => ref
                          .read(diagnosticsControllerProvider.notifier)
                          .openOemAutostartSettings(),
                    ),
                    onOpenBattery: () => _run(
                      context,
                      () => ref
                          .read(permissionsControllerProvider.notifier)
                          .openSettings(PermissionKind.batteryOptimization),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Recent events',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _EventsCard(events: snapshot.events),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => unawaited(_copyReport(context, snapshot)),
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copy diagnostics'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The report stays on this device until you paste it '
                    'somewhere. It contains device, permission and enforcement '
                    'state, plus recent event types — never app contents.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.diagnostics});

  final DeviceDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allGood = diagnostics.allRequiredChecks;
    final background = allGood
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.errorContainer;
    final foreground = allGood
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onErrorContainer;
    final device = [
      diagnostics.manufacturer,
      if (diagnostics.model.isNotEmpty) diagnostics.model,
    ].join(' ');
    final android = diagnostics.sdkInt > 0
        ? 'Android SDK ${diagnostics.sdkInt}'
        : 'Android';

    final String enforcement;
    if (diagnostics.isLocked) {
      enforcement = 'Daily limit locked';
    } else if (!diagnostics.serviceConfigured) {
      enforcement = 'No active limit configured';
    } else {
      enforcement =
          '${diagnostics.monitoredCount} '
          '${diagnostics.monitoredCount == 1 ? 'app' : 'apps'} · '
          '${formatDuration(diagnostics.limitSeconds)} daily limit';
    }

    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  allGood
                      ? Icons.verified_user_outlined
                      : Icons.gpp_maybe_outlined,
                  size: 30,
                  color: foreground,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allGood ? 'Ready to protect' : 'Protection needs work',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$device · $android',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value:
                    diagnostics.passedRequiredChecks /
                    DeviceDiagnostics.requiredCheckCount,
                minHeight: 6,
                color: foreground,
                backgroundColor: foreground.withValues(alpha: 0.18),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${diagnostics.passedRequiredChecks} of '
              '${DeviceDiagnostics.requiredCheckCount} essential checks passed',
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
            const SizedBox(height: 8),
            Text(
              enforcement,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (diagnostics.powerSaveMode) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.battery_saver, size: 16, color: foreground),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Battery saver is on now. The watcher may be delayed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.title,
    required this.detail,
    required this.passed,
    required this.onFix,
    this.fixLabel = 'Fix',
    this.isOptional = false,
  });

  final String title;
  final String detail;
  final bool passed;
  final VoidCallback onFix;
  final String fixLabel;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = passed
        ? theme.colorScheme.primary
        : isOptional
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          passed
              ? Icons.check_circle
              : isOptional
              ? Icons.info_outline
              : Icons.error_outline,
          color: colour,
        ),
        title: Text(title),
        subtitle: Text(
          detail,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        trailing: passed
            ? Text(
                'OK',
                style: theme.textTheme.labelSmall?.copyWith(color: colour),
              )
            : TextButton(onPressed: onFix, child: Text(fixLabel)),
      ),
    );
  }
}

class _OemCard extends StatelessWidget {
  const _OemCard({
    required this.guidance,
    required this.onOpenAutostart,
    required this.onOpenBattery,
  });

  final OemGuidance guidance;
  final VoidCallback onOpenAutostart;
  final VoidCallback onOpenBattery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Keep Lockout running on ${guidance.label}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'OEM battery managers can stop the watcher even after Android '
              'grants the permission. These steps are the ones that matter most.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < guidance.steps.length; index++)
              _StepRow(index: index + 1, text: guidance.steps[index]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (guidance.hasAutostartShortcut)
                  OutlinedButton.icon(
                    onPressed: onOpenAutostart,
                    icon: const Icon(Icons.rocket_launch_outlined),
                    label: const Text('Open autostart settings'),
                  ),
                OutlinedButton.icon(
                  onPressed: onOpenBattery,
                  icon: const Icon(Icons.battery_alert_outlined),
                  label: const Text('Open battery settings'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Names vary by ROM. If a shortcut is missing, use the steps '
              'above in your phone settings.',
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

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index.',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsCard extends StatelessWidget {
  const _EventsCard({required this.events});

  final List<DiagnosticEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = events.reversed.take(12).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: visible.isEmpty
            ? Text(
                'No events recorded yet. Start the watcher and come back if '
                'something stops working.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final event in visible)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatDiagnosticClock(event.at),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _LevelBadge(level: event.level),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.message,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (events.length > visible.length) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Showing the latest ${visible.length} of '
                      '${events.length} events.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = switch (level) {
      'ERROR' => theme.colorScheme.error,
      'WARN' => theme.colorScheme.tertiary,
      _ => theme.colorScheme.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colour,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
