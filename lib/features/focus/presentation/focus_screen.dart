import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/duration_format.dart';
import '../../../core/utils/focus_window.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../domain/entities/usage_settings.dart';
import '../../../domain/usecases/focus_lock.dart';
import '../../limits/presentation/monitored_apps_controller.dart';
import '../../limits/presentation/set_limits_screen.dart';
import '../../limits/presentation/settings_controller.dart';

/// Hard focus windows on top of the daily limit.
///
/// Both features apply to the apps selected in Limit & apps. The overnight lock
/// is fixed at 00:00-08:00; the study lock is a one-off session that starts now
/// and cannot be stopped until its end time.
class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final monitored = ref.watch(monitoredAppsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Focus locks')),
      body: AppResumeObserver(
        onResume: () => ref.read(settingsControllerProvider.notifier).reload(),
        child: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            debugPrint('Focus settings load failed: $error');
            return ErrorRetryView(
              title: "Couldn't load your focus locks",
              message: 'Please try again.',
              onRetry: () => ref.invalidate(settingsControllerProvider),
            );
          },
          data: (settingsValue) => monitored.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) {
              debugPrint('Focus apps load failed: $error');
              return ErrorRetryView(
                title: "Couldn't load your apps",
                message: 'Please try again.',
                onRetry: () => ref.invalidate(monitoredAppsControllerProvider),
              );
            },
            data: (apps) => _FocusEditor(
              settings: settingsValue,
              appCount: apps.where((app) => app.isEnabled).length,
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusEditor extends ConsumerStatefulWidget {
  const _FocusEditor({required this.settings, required this.appCount});

  final UsageSettings settings;
  final int appCount;

  @override
  ConsumerState<_FocusEditor> createState() => _FocusEditorState();
}

class _FocusEditorState extends ConsumerState<_FocusEditor> {
  static const List<int> _presetMinutes = [25, 45, 60, 90, 120, 180, 240];

  late int _minutes;
  bool _saving = false;

  UsageSettings get _settings => widget.settings;

  DateTime? get _studyEndsAt => _settings.studyEndsAt;

  bool get _studyActive => isStudyLockActive(_settings, DateTime.now());

  bool get _overnightActive =>
      _settings.overnightLockEnabled && isOvernightLockWindow(DateTime.now());

  @override
  void initState() {
    super.initState();
    _minutes = _presetMinutes.contains(_settings.studyLengthMinutes)
        ? _settings.studyLengthMinutes
        : 60;
  }

  Future<void> _setOvernight(bool enabled) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .setOvernightLock(enabled);
    } on Object catch (error) {
      debugPrint('Overnight lock update failed: $error');
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _startStudy() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .startStudySession(_minutes);
      if (!mounted) return;
      final endsAt = ref.read(settingsControllerProvider).value?.studyEndsAt;
      final suffix = endsAt == null
          ? ''
          : ' It ends at ${formatClockTime(endsAt)}.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Study lock started.$suffix')));
    } on Object catch (error) {
      debugPrint('Study lock start failed: $error');
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Couldn't update your focus lock. Please try again."),
      ),
    );
  }

  Future<void> _openLimits(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SetLimitsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasApps = widget.appCount > 0;
    final studyEndsAt = _studyEndsAt;
    final countLabel =
        '${widget.appCount} ${widget.appCount == 1 ? 'app' : 'apps'}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          'Focus locks use the apps you choose for your daily limit.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.apps),
            title: const Text('Selected apps'),
            subtitle: Text(
              hasApps ? countLabel : 'No apps selected yet',
              style: theme.textTheme.bodySmall,
            ),
            trailing: TextButton(
              onPressed: () => _openLimits(context),
              child: Text(hasApps ? 'Change' : 'Choose apps'),
            ),
          ),
        ),
        if (!hasApps) ...[
          const SizedBox(height: 8),
          Text(
            'Choose at least one app before turning on a focus lock.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Overnight lock', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: SwitchListTile(
            title: const Text('Block every night'),
            subtitle: Text(_overnightSubtitle),
            value: _settings.overnightLockEnabled,
            onChanged: hasApps && !_saving && !_overnightActive
                ? _setOvernight
                : null,
          ),
        ),
        if (_overnightActive) ...[
          const SizedBox(height: 8),
          _FocusNotice(
            icon: Icons.nightlight_outlined,
            text:
                'Overnight lock is active. Your selected apps stay blocked '
                'until ${formatClockTime(overnightLockEndFor(DateTime.now()))}.',
          ),
        ],
        const SizedBox(height: 24),
        Text('Study lock', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _studyActive ? 'Study lock is on' : 'Start study lock',
                  ),
                  subtitle: Text(_studySubtitle),
                  value: _studyActive,
                  onChanged: hasApps && !_saving && !_studyActive
                      ? (enabled) {
                          if (enabled) _startStudy();
                        }
                      : null,
                ),
                if (!_studyActive) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Study for',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final minutes in _presetMinutes)
                        ChoiceChip(
                          label: Text(formatDuration(minutes * 60)),
                          selected: _minutes == minutes,
                          onSelected: hasApps && !_saving
                              ? (_) => setState(() => _minutes = minutes)
                              : null,
                        ),
                    ],
                  ),
                ] else if (studyEndsAt != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _studyProgress(studyEndsAt),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_studyActive) ...[
          const SizedBox(height: 8),
          _FocusNotice(
            icon: Icons.timer_outlined,
            text:
                'Selected apps are blocked until '
                '${formatClockTime(studyEndsAt!)}. You cannot turn this off '
                'before then.',
          ),
        ],
        const SizedBox(height: 24),
        _FocusNotice(
          icon: Icons.lock_outline,
          text:
              'A focus lock cannot be turned off while it is running. '
              'Opening a selected app shows the Lockout block screen.',
        ),
      ],
    );
  }

  String get _overnightSubtitle {
    if (widget.appCount == 0) {
      return 'Choose apps in Limit & apps first.';
    }
    if (_overnightActive) {
      return 'On until 8:00 AM. It cannot be turned off until then.';
    }
    if (_settings.overnightLockEnabled) {
      return 'On every night, 12:00 AM to 8:00 AM.';
    }
    return 'Block your selected apps from 12:00 AM to 8:00 AM.';
  }

  String get _studySubtitle {
    if (widget.appCount == 0) {
      return 'Choose apps in Limit & apps first.';
    }
    final endsAt = _studyEndsAt;
    if (_studyActive && endsAt != null) {
      return 'Ends at ${formatClockTime(endsAt)}. '
          'You cannot turn it off before then.';
    }
    if (_settings.studyEndsAt != null) {
      return 'The last study lock has finished.';
    }
    return 'Close your selected apps now and keep them blocked for '
        '${formatDuration(_minutes * 60)}.';
  }

  double _studyProgress(DateTime endsAt) {
    final startsAt = endsAt.subtract(Duration(minutes: _minutes));
    final total = endsAt.difference(startsAt).inSeconds;
    if (total <= 0) return 0;
    final elapsed = DateTime.now().difference(startsAt).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

class _FocusNotice extends StatelessWidget {
  const _FocusNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
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
