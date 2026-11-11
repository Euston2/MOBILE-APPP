import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../core/widgets/lockout_ui.dart';
import '../../../domain/entities/usage_settings.dart';
import '../../../domain/usecases/study_timer.dart';
import '../../limits/presentation/monitored_apps_controller.dart';
import '../../limits/presentation/set_limits_screen.dart';
import '../../limits/presentation/settings_controller.dart';

/// Cumulative study timer, daily focus goal and missed-goal automation.
///
/// The timer is deliberately separate from the one-off study lock on the Focus
/// locks screen: this screen tracks how much focus the user has done today,
/// while the study lock closes selected apps immediately for a fixed session.
class StudyTimerScreen extends ConsumerWidget {
  const StudyTimerScreen({super.key});

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
            Text('Study timer', style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
      body: AppResumeObserver(
        onResume: () => ref.read(settingsControllerProvider.notifier).reload(),
        child: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            debugPrint('Study timer settings load failed: $error');
            return ErrorRetryView(
              title: "Couldn't load your study timer",
              message: 'Please try again.',
              onRetry: () => ref.invalidate(settingsControllerProvider),
            );
          },
          data: (settingsValue) => monitored.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) {
              debugPrint('Study timer apps load failed: $error');
              return ErrorRetryView(
                title: "Couldn't load your apps",
                message: 'Please try again.',
                onRetry: () => ref.invalidate(monitoredAppsControllerProvider),
              );
            },
            data: (apps) => _StudyTimerBody(
              settings: settingsValue,
              appCount: apps.where((app) => app.isEnabled).length,
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyTimerBody extends ConsumerStatefulWidget {
  const _StudyTimerBody({required this.settings, required this.appCount});

  final UsageSettings settings;
  final int appCount;

  @override
  ConsumerState<_StudyTimerBody> createState() => _StudyTimerBodyState();
}

class _StudyTimerBodyState extends ConsumerState<_StudyTimerBody> {
  static const List<int> _presetMinutes = [15, 25, 45, 60, 90, 120];

  Timer? _ticker;
  late int _selectedMinutes;
  bool _saving = false;

  UsageSettings get _settings => widget.settings;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = _settings.focusSessionLengthMinutes
        .clamp(minFocusSessionMinutes, maxFocusSessionMinutes)
        .toInt();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String failure) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
    } on Object catch (error) {
      debugPrint('Study timer action failed: $error');
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
    final settings = _settings;
    final minutes = await _showFocusMinutesDialog(
      context,
      title: 'Daily focus goal',
      initialMinutes: settings.focusGoalMinutes,
      allowOff: true,
      maxMinutes: maxFocusGoalMinutes,
    );
    if (minutes == null || !mounted) return;
    await _run(
      () => ref.read(settingsControllerProvider.notifier).setFocusGoal(minutes),
      "Couldn't update your daily goal.",
    );
  }

  Future<void> _pickCustomSession() async {
    final minutes = await _showFocusMinutesDialog(
      context,
      title: 'Focus session length',
      initialMinutes: _selectedMinutes,
      allowOff: false,
      maxMinutes: maxFocusSessionMinutes,
    );
    if (minutes == null || !mounted) return;
    setState(() => _selectedMinutes = minutes);
  }

  Future<void> _pickCutoff() async {
    final settings = _settings;
    final selected = await showTimePicker(
      context: context,
      helpText: 'Block selected apps at',
      initialTime: TimeOfDay(
        hour: settings.focusCutoffMinutes ~/ 60,
        minute: settings.focusCutoffMinutes % 60,
      ),
    );
    if (selected == null || !mounted) return;
    await _run(
      () => ref
          .read(settingsControllerProvider.notifier)
          .setFocusCutoff(selected.hour * 60 + selected.minute),
      "Couldn't update the focus cutoff.",
    );
  }

  Future<void> _setAutoBlock(bool enabled) => _run(
    () => ref
        .read(settingsControllerProvider.notifier)
        .setFocusAutoBlock(enabled),
    "Couldn't update automatic blocking.",
  );

  Future<void> _start() => _run(
    () => ref
        .read(settingsControllerProvider.notifier)
        .startFocusSession(_selectedMinutes),
    "Couldn't start the focus timer.",
  );

  Future<void> _pause() => _run(
    () => ref.read(settingsControllerProvider.notifier).pauseFocusSession(),
    "Couldn't pause the focus timer.",
  );

  Future<void> _resume() => _run(
    () => ref.read(settingsControllerProvider.notifier).resumeFocusSession(),
    "Couldn't resume the focus timer.",
  );

  Future<void> _end() => _run(
    () => ref.read(settingsControllerProvider.notifier).stopFocusSession(),
    "Couldn't end the focus timer.",
  );

  Future<void> _openLimits() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SetLimitsScreen()));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final settings = _settings;
    final goalSeconds = settings.focusGoalMinutes * 60;
    final todaySeconds = focusSecondsForToday(settings, now);
    final running = isFocusSessionRunning(settings, now);
    final paused = isFocusSessionPaused(settings, now);
    final blockActive = isFocusGoalBlockActive(settings, now);
    final remaining = focusSessionRemainingSeconds(settings, now);
    final clockSeconds = running || paused ? remaining : _selectedMinutes * 60;
    final progress = goalSeconds <= 0
        ? 0.0
        : (todaySeconds / goalSeconds).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          'Focus time is cumulative for today. Start a timer for a study '
          'session and let the total build toward your daily goal.',
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
                        : Icons.track_changes_outlined,
                    color: blockActive
                        ? LockoutPalette.coral
                        : LockoutPalette.mint,
                    size: 38,
                  ),
                  const SizedBox(width: 10),
                  Text("Today's focus", style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatDuration(todaySeconds),
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
                  '${formatDuration(todaySeconds)} of '
                  '${formatDuration(goalSeconds)} goal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: blockActive
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else
                Text(
                  'No goal set. You can still track focus sessions.',
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
                    settings.focusGoalMinutes > 0
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
          _TimerNotice(
            icon: Icons.block,
            error: true,
            text:
                'You missed today’s focus goal, so the selected apps are '
                'blocked until midnight. Finish '
                '${formatDuration((goalSeconds - todaySeconds).clamp(0, goalSeconds).toInt())} '
                'more focus to unlock them early.',
          ),
        ],
        const SizedBox(height: 16),
        LockoutCardSurface(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Focus timer',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      running
                          ? 'Focusing'
                          : paused
                          ? 'Paused'
                          : 'Ready',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                formatTimerClock(clockSeconds),
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: paused
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                running
                    ? 'The clock keeps running while this screen is open or '
                          'closed.'
                    : paused
                    ? 'Resume when you are ready. The remaining time is '
                          'saved.'
                    : 'Pick a length, then start focusing.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (running)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _pause,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _saving ? null : _end,
                      child: const Text('End'),
                    ),
                  ],
                )
              else if (paused)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _resume,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Resume'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _saving ? null : _end,
                      child: const Text('End'),
                    ),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: _saving ? null : _start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start focus'),
                ),
              if (!running && !paused) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final minutes in _presetMinutes)
                      ChoiceChip(
                        label: Text(formatDuration(minutes * 60)),
                        selected: _selectedMinutes == minutes,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _selectedMinutes = minutes),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.tune, size: 18),
                      label: const Text('Custom'),
                      onPressed: _saving ? null : _pickCustomSession,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
                  settings.focusAutoBlockEnabled
                      ? 'After ${formatClockTime(focusCutoffFor(now, settings.focusCutoffMinutes))}, '
                            'selected apps stay blocked until the goal is met.'
                      : 'Optionally close the selected apps after a cutoff '
                            'time when the goal is still short.',
                ),
                value: settings.focusAutoBlockEnabled,
                onChanged:
                    blockActive || _saving || settings.focusGoalMinutes <= 0
                    ? null
                    : _setAutoBlock,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Start blocking at'),
                subtitle: Text(
                  formatClockTime(
                    focusCutoffFor(now, settings.focusCutoffMinutes),
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
          _TimerNotice(
            icon: Icons.apps,
            text:
                'No apps are selected. The timer still works, but the '
                'missed-goal block has nothing to close.',
            action: TextButton(
              onPressed: _openLimits,
              child: const Text('Choose apps'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _TimerNotice(
          icon: Icons.info_outline,
          text:
              'Meeting the goal lifts the automatic block before midnight. '
              'The block cannot be turned off or relaxed while it is active; '
              'start another focus session to clear it early.',
        ),
      ],
    );
  }
}

class _TimerNotice extends StatelessWidget {
  const _TimerNotice({
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

Future<int?> _showFocusMinutesDialog(
  BuildContext context, {
  required String title,
  required int initialMinutes,
  required bool allowOff,
  required int maxMinutes,
}) {
  final minValue = allowOff ? 0 : minFocusSessionMinutes;
  final maxValue = maxMinutes;
  var value = initialMinutes.clamp(minValue, maxValue).toDouble();

  return showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final rounded = ((value / 5).round() * 5)
            .clamp(minValue, maxValue)
            .toInt();
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                allowOff && rounded == 0
                    ? 'No goal'
                    : formatDuration(rounded * 60),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Slider(
                value: rounded.toDouble(),
                min: minValue.toDouble(),
                max: maxValue.toDouble(),
                divisions: ((maxValue - minValue) / 5).round(),
                label: allowOff && rounded == 0
                    ? 'Off'
                    : formatDuration(rounded * 60),
                onChanged: (next) => setDialogState(() => value = next),
              ),
              Text(
                allowOff
                    ? 'Choose a goal, or slide to the start to turn it off.'
                    : 'Sessions can run from 5 minutes to 8 hours.',
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
