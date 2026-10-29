import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../domain/entities/installed_app.dart';
import '../../../domain/entities/monitored_app.dart';
import '../../../domain/entities/usage_settings.dart';
import '../../home/presentation/today_usage_controller.dart';
import 'monitored_apps_controller.dart';
import 'settings_controller.dart';

/// Pick the monitored apps and the combined daily limit.
///
/// The whole screen becomes read-only while the lock is active (Stage 4); the
/// guard is already wired so the UI cannot be edited when `isLocked` is true.
class SetLimitsScreen extends ConsumerWidget {
  const SetLimitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final monitored = ref.watch(monitoredAppsControllerProvider);
    final installed = ref.watch(installedAppsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Limit & apps')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetryView(
          message: '$error',
          onRetry: () => ref.invalidate(settingsControllerProvider),
        ),
        data: (settingsValue) => monitored.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorRetryView(
            message: '$error',
            onRetry: () => ref.invalidate(monitoredAppsControllerProvider),
          ),
          data: (monitoredApps) => installed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorRetryView(
              message: '$error',
              onRetry: () => ref.invalidate(installedAppsProvider),
            ),
            data: (installedApps) => _LimitsEditor(
              settings: settingsValue,
              monitored: monitoredApps,
              installed: installedApps,
            ),
          ),
        ),
      ),
    );
  }
}

class _LimitsEditor extends ConsumerStatefulWidget {
  const _LimitsEditor({
    required this.settings,
    required this.monitored,
    required this.installed,
  });

  final UsageSettings settings;
  final List<MonitoredApp> monitored;
  final List<InstalledApp> installed;

  @override
  ConsumerState<_LimitsEditor> createState() => _LimitsEditorState();
}

class _LimitsEditorState extends ConsumerState<_LimitsEditor> {
  static const List<int> _presetMinutes = [15, 30, 45, 60, 90, 120, 180];

  late int _minutes;
  late Set<String> _selected;
  late Map<String, String> _labelByPackage;
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _saving = false;

  bool get _locked => widget.settings.isLocked;

  @override
  void initState() {
    super.initState();
    final initialSeconds = widget.settings.hasLimit
        ? widget.settings.dailyLimitSeconds
        : 3600;
    _minutes = (initialSeconds / 60).round().clamp(15, 480);
    _selected = {
      for (final app in widget.monitored)
        if (app.isEnabled) app.packageName,
    };
    _labelByPackage = {
      for (final app in widget.installed) app.packageName: app.displayName,
      for (final app in widget.monitored)
        if (!widget.installed.any((i) => i.packageName == app.packageName))
          app.packageName: app.displayName,
    };
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<MapEntry<String, String>> get _visibleApps {
    final entries =
        _labelByPackage.entries
            .where(
              (entry) =>
                  _query.isEmpty ||
                  entry.value.toLowerCase().contains(_query) ||
                  entry.key.toLowerCase().contains(_query),
            )
            .toList()
          ..sort(
            (a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()),
          );
    return entries;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final apps =
        [
          for (final packageName in _selected)
            MonitoredApp(
              packageName: packageName,
              displayName: _labelByPackage[packageName] ?? packageName,
            ),
        ]..sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
        );

    try {
      await ref.read(monitoredAppsControllerProvider.notifier).replaceAll(apps);
      await ref
          .read(settingsControllerProvider.notifier)
          .saveLimit(_minutes * 60);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Limit and apps saved')));
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSave = !_locked && !_saving && _selected.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (_locked) ...[
                _LockedNotice(nextResetAt: widget.settings.nextResetAt),
                const SizedBox(height: 12),
              ],
              Text('Daily limit', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      Text(
                        formatDuration(_minutes * 60),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'combined across ${_selected.length} '
                        '${_selected.length == 1 ? 'app' : 'apps'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: _minutes.toDouble(),
                        min: 15,
                        max: 480,
                        divisions: 31,
                        label: formatDuration(_minutes * 60),
                        onChanged: _locked
                            ? null
                            : (value) =>
                                  setState(() => _minutes = value.round()),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final preset in _presetMinutes)
                            ChoiceChip(
                              label: Text(formatDuration(preset * 60)),
                              selected: _minutes == preset,
                              onSelected: _locked
                                  ? null
                                  : (_) => setState(() => _minutes = preset),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('Apps', style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    '${_selected.length} selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search installed apps',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
              ),
              const SizedBox(height: 8),
              for (final entry in _visibleApps)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.value),
                  subtitle: Text(
                    entry.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: _selected.contains(entry.key),
                  onChanged: _locked
                      ? null
                      : (checked) => setState(() {
                          if (checked ?? false) {
                            _selected.add(entry.key);
                          } else {
                            _selected.remove(entry.key);
                          }
                        }),
                ),
              if (_visibleApps.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No apps match "$_query".',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Only the selected apps count towards the limit. Lockout '
                'never monitors itself.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _locked
                        ? 'Locked'
                        : _selected.isEmpty
                        ? 'Select at least one app'
                        : 'Save changes',
                  ),
          ),
        ),
      ],
    );
  }
}

class _LockedNotice extends StatelessWidget {
  const _LockedNotice({required this.nextResetAt});

  final DateTime nextResetAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = nextResetAt.difference(DateTime.now());
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Locked until 00:00 (${formatCountdown(remaining)}). '
                'The limit and apps cannot be changed.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
