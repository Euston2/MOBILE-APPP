import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/utils/app_names.dart';
import '../../../core/utils/duration_format.dart';
import '../../../domain/entities/history_day.dart';
import '../../../domain/entities/installed_app.dart';
import '../../../domain/entities/monitored_app.dart';
import '../../../domain/usecases/history_csv.dart';
import '../../../domain/usecases/history_report.dart';
import '../../home/presentation/today_usage_controller.dart';
import '../../limits/presentation/monitored_apps_controller.dart';
import 'history_controller.dart';
import 'history_format.dart';
import 'widgets/focus_comparison_chart.dart';
import 'widgets/history_chart.dart';

/// Archived daily usage, a week/month chart, and a CSV share action.
///
/// Today's live number is deliberately not duplicated here: it is only saved at
/// midnight, and Home remains the place to see the current countdown.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(historyControllerProvider);
    final range = ref.watch(historyRangeProvider);
    final theme = Theme.of(context);

    final installed =
        ref.watch(installedAppsProvider).value ?? const <InstalledApp>[];
    final monitored =
        ref.watch(monitoredAppsControllerProvider).value ??
        const <MonitoredApp>[];
    final labels = <String, String>{
      for (final app in installed)
        app.packageName: friendlyAppName(app.packageName, app.displayName),
      for (final app in monitored)
        app.packageName: friendlyAppName(app.packageName, app.displayName),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Share history',
            onPressed: (report.value?.hasData ?? false)
                ? () => _shareCsv(context, ref, report.value!)
                : null,
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          debugPrint('History load failed: $error');
          return _HistoryError(
            onRetry: () => ref.invalidate(historyControllerProvider),
          );
        },
        data: (report) => RefreshIndicator(
          onRefresh: () =>
              ref.read(historyControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _RangeSelector(range: range),
              const SizedBox(height: 16),
              if (!report.hasData)
                const _EmptyHistory()
              else ...[
                _StatsCard(report: report, range: range),
                const SizedBox(height: 20),
                _ChartCard(report: report),
                const SizedBox(height: 16),
                _ComparisonCard(report: report),
                const SizedBox(height: 24),
                Text('Days', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final day in report.days.reversed.where(
                  (day) => day.hasActivity,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DayTile(day: day, labels: labels),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Each day is saved at midnight. Today\'s usage is on Home.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareCsv(
    BuildContext context,
    WidgetRef ref,
    HistoryReport report,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(historyExporterProvider)
          .shareCsv(
            subject: 'Lockout history (${report.days.length} days)',
            csv: historyCsv(report.days),
          );
    } on Object catch (error) {
      debugPrint('History share failed: $error');
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't share your history. Please try again."),
        ),
      );
    }
  }
}

class _RangeSelector extends ConsumerWidget {
  const _RangeSelector({required this.range});

  final int range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 7, label: Text('7 days')),
          ButtonSegment(value: 30, label: Text('30 days')),
        ],
        selected: {range},
        showSelectedIcon: false,
        onSelectionChanged: (selection) {
          if (selection.isEmpty) return;
          ref.read(historyRangeProvider.notifier).select(selection.first);
        },
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.report, required this.range});

  final HistoryReport report;
  final int range;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = report.stats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Last $range days',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${stats.trackedDays} of $range days recorded',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Total',
                    value: formatDuration(stats.totalSeconds),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Daily average',
                    value: formatDuration(stats.averageSeconds),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Over limit',
                    value: '${stats.limitHitDays}',
                    color: stats.limitHitDays > 0
                        ? theme.colorScheme.error
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Focus time',
                    value: formatDuration(stats.totalFocusSeconds),
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Late night',
                    value: formatDuration(stats.totalLateNightSeconds),
                    color: stats.totalLateNightSeconds > 0
                        ? theme.colorScheme.error
                        : null,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Under limit',
                    value: '${stats.underLimitDays}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.report});

  final HistoryReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Daily usage',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  rangeLabel(report.days),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 220, child: HistoryChart(days: report.days)),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.report});

  final HistoryReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Social vs focus',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  rangeLabel(report.days),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Late night is the part of social screen time used between '
              '12:00 AM and 8:00 AM.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FocusComparisonChart(days: report.days),
          ],
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.labels});

  final HistoryDay day;
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final apps = day.apps.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final badgeColor = day.hitLimit
        ? colors.errorContainer
        : colors.primaryContainer;
    final onBadge = day.hitLimit
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;

    final leading = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekdayShort(day.date).toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: onBadge,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${day.date.day}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: onBadge,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final title = Text(
      day.hasUsage
          ? formatDuration(day.totalSeconds)
          : '${formatDuration(day.focusSeconds)} focus',
      style: theme.textTheme.titleMedium,
    );
    final subtitle = Text(
      _subtitle(day),
      style: theme.textTheme.bodySmall?.copyWith(
        color: day.hitLimit ? colors.error : colors.onSurfaceVariant,
      ),
    );

    if (apps.isEmpty) {
      return Card(
        child: ListTile(leading: leading, title: title, subtitle: subtitle),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: [
          const Divider(height: 1),
          for (final entry in apps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      labels[entry.key] ??
                          friendlyAppName(
                            entry.key,
                            null,
                            fallback: removedAppName,
                          ),
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatDuration(entry.value),
                        style: theme.textTheme.bodyMedium,
                      ),
                      if ((day.lateNightApps[entry.key] ?? 0) > 0)
                        Text(
                          '${formatDuration(day.lateNightApps[entry.key]!)} '
                          'late night',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.error,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _subtitle(HistoryDay day) {
    final parts = <String>[];
    if (!day.hasLimit) {
      parts.add('No limit set');
    } else if (day.hitLimit) {
      final hitAt = day.limitHitAt;
      parts.add(
        hitAt == null
            ? 'Limit reached'
            : 'Limit reached at ${clockTime(hitAt)}',
      );
    } else {
      parts.add(
        '${formatDuration(day.remainingSeconds)} left of '
        '${formatDuration(day.limitSeconds)}',
      );
    }
    if (day.hasFocus) parts.add('${formatDuration(day.focusSeconds)} focus');
    if (day.hasLateNight) {
      parts.add('${formatDuration(day.lateNightSeconds)} late night');
    }
    return parts.join(' · ');
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_toggle_off,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text('No history yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Finished days appear here after the midnight reset. '
              'Today\'s usage stays on Home.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 72),
        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(
          'Couldn\'t load your history',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Your history is still on this phone. Please try again.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}
