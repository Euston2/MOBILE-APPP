import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../core/widgets/lockout_ui.dart';
import '../../../domain/entities/usage_settings.dart';
import '../../../domain/usecases/reading_goal.dart';
import '../../limits/presentation/monitored_apps_controller.dart';
import '../../limits/presentation/set_limits_screen.dart';
import '../../limits/presentation/settings_controller.dart';
import '../../reader/presentation/reading_progress.dart';

/// Daily reading goal and the optional block when it is missed.
///
/// Reading time is recorded by the Reader's article screen in drift. This screen
/// only decides what the goal is and when the selected apps should be closed if
/// the goal is still short.
class ReadingGoalScreen extends ConsumerWidget {
  const ReadingGoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final monitored = ref.watch(monitoredAppsControllerProvider);

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
            Text('Reading goal', style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
      body: AppResumeObserver(
        onResume: () {
          unawaited(ref.read(settingsControllerProvider.notifier).reload());
          ref.invalidate(readingSecondsTodayProvider);
        },
        child: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            debugPrint('Reading goal settings load failed: $error');
            return ErrorRetryView(
              title: "Couldn't load your reading goal",
              message: 'Please try again.',
              onRetry: () => ref.invalidate(settingsControllerProvider),
            );
          },
          data: (settingsValue) => monitored.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) {
              debugPrint('Reading goal apps load failed: $error');
              return ErrorRetryView(
                title: "Couldn't load your apps",
                message: 'Please try again.',
                onRetry: () => ref.invalidate(monitoredAppsControllerProvider),
              );
            },
            data: (apps) => _ReadingGoalBody(
              settings: settingsValue,
              appCount: apps.where((app) => app.isEnabled).length,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingGoalBody extends ConsumerStatefulWidget {
  const _ReadingGoalBody({required this.settings, required this.appCount});

  final UsageSettings settings;
  final int appCount;

  @override
  ConsumerState<_ReadingGoalBody> createState() => _ReadingGoalBodyState();
}

class _ReadingGoalBodyState extends ConsumerState<_ReadingGoalBody> {
  bool _saving = false;

  UsageSettings get _settings => widget.settings;

  Future<void> _run(Future<void> Function() action, String failure) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
    } on Object catch (error) {
      debugPrint('Reading goal action failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickGoal() async {
    final minutes = await _showReadingMinutesDialog(
      context,
      initialMinutes: _settings.readingGoalMinutes,
    );
    if (minutes == null || !mounted) return;
    await _run(
      () =>
          ref.read(settingsControllerProvider.notifier).setReadingGoal(minutes),
      "Couldn't update your daily reading goal.",
    );
  }

  Future<void> _pickCutoff() async {
    final selected = await showTimePicker(
      context: context,
      helpText: 'Block selected apps at',
      initialTime: TimeOfDay(
        hour: _settings.readingCutoffMinutes ~/ 60,
        minute: _settings.readingCutoffMinutes % 60,
      ),
    );
    if (selected == null || !mounted) return;
    await _run(
      () => ref
          .read(settingsControllerProvider.notifier)
          .setReadingCutoff(selected.hour * 60 + selected.minute),
      "Couldn't update the reading cutoff.",
    );
  }

  Future<void> _setAutoBlock(bool enabled) => _run(
    () => ref
        .read(settingsControllerProvider.notifier)
        .setReadingAutoBlock(enabled),
    "Couldn't update automatic blocking.",
  );

  Future<void> _openLimits() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SetLimitsScreen()));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final settings = _settings;
    final reading = ref.watch(readingSecondsTodayProvider);
    final readingSeconds = reading.value ?? 0;
    final goalSeconds = settings.readingGoalMinutes * 60;
    final blockActive = isReadingGoalBlockActive(settings, now, readingSeconds);
    final remaining = readingGoalRemainingSeconds(settings, readingSeconds);
    final progress = goalSeconds <= 0
        ? 0.0
        : (readingSeconds / goalSeconds).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          'Reading time comes from the Reader tab. Read an article for a few '
          'minutes and the total builds toward your daily goal.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        LockoutCardSurface(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          borderColor: blockActive
              ? LockoutPalette.coral.withValues(alpha: 0.34)
              : LockoutPalette.mint.withValues(alpha: 0.2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (blockActive ? LockoutPalette.coral : LockoutPalette.mint)
                  .withValues(alpha: 0.1),
              LockoutPalette.surface,
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  LockoutIconBadge(
                    blockActive
                        ? Icons.lock_clock_outlined
                        : Icons.menu_book_outlined,
                    color: blockActive
                        ? LockoutPalette.coral
                        : LockoutPalette.mint,
                    size: 38,
                  ),
                  const SizedBox(width: 10),
                  Text("Today's reading", style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatDuration(readingSeconds),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: blockActive
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              if (goalSeconds > 0) ...[
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  color: blockActive ? theme.colorScheme.error : null,
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatDuration(readingSeconds)} of '
                  '${formatDuration(goalSeconds)} goal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: blockActive
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else
                Text(
                  'No goal set. Reading time is still tracked for today.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: blockActive || _saving ? null : _pickGoal,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    settings.readingGoalMinutes > 0
                        ? 'Edit goal'
                        : 'Set daily goal',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (blockActive) ...[
          const SizedBox(height: 8),
          _ReadingNotice(
            icon: Icons.block,
            error: true,
            text:
                'You missed today’s reading goal, so the selected apps are '
                'blocked until midnight. Read ${formatDuration(remaining)} more '
                'in Reader to unlock them early.',
          ),
        ],
        if (reading.hasError) ...[
          const SizedBox(height: 8),
          _ReadingNotice(
            icon: Icons.error_outline,
            error: true,
            text:
                "Today's reading time could not be loaded. Open Reader and "
                'read an article, then come back.',
          ),
        ],
        const SizedBox(height: 20),
        LockoutSectionLabel('Goal automation'),
        const SizedBox(height: 8),
        LockoutCardSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Block if I miss my goal'),
                subtitle: Text(
                  settings.readingAutoBlockEnabled
                      ? 'After ${formatClockTime(readingCutoffFor(now, settings.readingCutoffMinutes))}, '
                            'selected apps stay blocked until the goal is met.'
                      : 'Optionally close the selected apps after a cutoff '
                            'time when the goal is still short.',
                ),
                value: settings.readingAutoBlockEnabled,
                onChanged:
                    blockActive || _saving || settings.readingGoalMinutes <= 0
                    ? null
                    : _setAutoBlock,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Start blocking at'),
                subtitle: Text(
                  formatClockTime(
                    readingCutoffFor(now, settings.readingCutoffMinutes),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: blockActive || _saving ? null : _pickCutoff,
              ),
            ],
          ),
        ),
        if (widget.appCount == 0) ...[
          const SizedBox(height: 8),
          _ReadingNotice(
            icon: Icons.apps,
            text:
                'No apps are selected. The goal still tracks reading, but the '
                'missed-goal block has nothing to close.',
            action: TextButton(
              onPressed: _openLimits,
              child: const Text('Choose apps'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const _ReadingNotice(
          icon: Icons.info_outline,
          text:
              'Reading time is counted only while an article is open in Reader '
              'and the app is in the foreground. The block lifts as soon as '
              'you reach the goal. Your own links count too.',
        ),
      ],
    );
  }
}

class _ReadingNotice extends StatelessWidget {
  const _ReadingNotice({
    required this.icon,
    required this.text,
    this.error = false,
    this.action,
  });

  final IconData icon;
  final String text;
  final bool error;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = error ? LockoutPalette.coral : LockoutPalette.amber;

    return LockoutCardSurface(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      borderColor: accent.withValues(alpha: error ? 0.34 : 0.22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LockoutIconBadge(icon, color: accent, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

Future<int?> _showReadingMinutesDialog(
  BuildContext context, {
  required int initialMinutes,
}) {
  const maxValue = maxReadingGoalMinutes;
  var value = initialMinutes.clamp(0, maxValue).toDouble();

  return showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final rounded = ((value / 5).round() * 5).clamp(0, maxValue).toInt();
        return AlertDialog(
          title: const Text('Daily reading goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rounded == 0 ? 'No goal' : formatDuration(rounded * 60),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Slider(
                value: rounded.toDouble(),
                min: 0,
                max: maxValue.toDouble(),
                divisions: maxValue ~/ 5,
                label: rounded == 0 ? 'Off' : formatDuration(rounded * 60),
                onChanged: (next) => setDialogState(() => value = next),
              ),
              Text(
                'Choose a goal, or slide to the start to turn it off. '
                'Five-minute steps.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(rounded),
              child: const Text('Set'),
            ),
          ],
        );
      },
    ),
  );
}
