import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_names.dart';
import '../../../core/utils/day_window.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../core/widgets/lockout_ui.dart';
import '../../../domain/entities/installed_app.dart';
import '../../../domain/entities/monitored_app.dart';
import '../../../domain/entities/usage_settings.dart';
import '../../../domain/usecases/focus_lock.dart';
import '../../home/presentation/today_usage_controller.dart';
import 'monitored_apps_controller.dart';
import 'settings_controller.dart';

/// Pick the monitored apps and the combined daily limit.
///
/// The whole screen becomes read-only while the daily lock or either focus lock
/// is active, so an active block cannot be relaxed from the editor.
class SetLimitsScreen extends ConsumerWidget {
  const SetLimitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final monitored = ref.watch(monitoredAppsControllerProvider);
    final installed = ref.watch(installedAppsProvider);

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
            Text('Limit & apps', style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          debugPrint('Limit settings load failed: $error');
          return ErrorRetryView(
            title: "Couldn't load your limit",
            message: 'Please try again.',
            onRetry: () => ref.invalidate(settingsControllerProvider),
          );
        },
        data: (settingsValue) => monitored.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            debugPrint('Monitored apps load failed: $error');
            return ErrorRetryView(
              title: "Couldn't load your apps",
              message: 'Please try again.',
              onRetry: () => ref.invalidate(monitoredAppsControllerProvider),
            );
          },
          data: (monitoredApps) => installed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) {
              debugPrint('Installed apps load failed: $error');
              return ErrorRetryView(
                title: "Couldn't load your apps",
                message: 'Please try again.',
                onRetry: () => ref.invalidate(installedAppsProvider),
              );
            },
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

  DateTime? get _focusUntil =>
      activeFocusLockEnd(widget.settings, DateTime.now());

  bool get _locked => widget.settings.isLocked || _focusUntil != null;

  bool get _hasPendingChange =>
      widget.settings.pendingLimitSeconds != null ||
      widget.monitored.any((app) => app.pendingEnabled != null);

  /// A limit is already in force today, so new values must wait for the next
  /// day. The first setup applies immediately. (Apps selected without a limit
  /// enforce nothing, so they do not count as configured.)
  bool get _alreadyConfigured => widget.settings.hasLimit;

  int get _activeAppCount =>
      widget.monitored.where((app) => app.isEnabled).length;

  @override
  void initState() {
    super.initState();
    final scheduledSeconds =
        widget.settings.pendingLimitSeconds ??
        (widget.settings.hasLimit ? widget.settings.dailyLimitSeconds : 3600);
    _minutes = (scheduledSeconds / 60).round().clamp(15, 480);
    _selected = {
      for (final app in widget.monitored)
        if (app.scheduledEnabled) app.packageName,
    };
    _labelByPackage = {
      for (final app in widget.installed)
        app.packageName: friendlyAppName(app.packageName, app.displayName),
      for (final app in widget.monitored)
        if (!widget.installed.any((i) => i.packageName == app.packageName))
          app.packageName: friendlyAppName(app.packageName, app.displayName),
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
                  _query.isEmpty || entry.value.toLowerCase().contains(_query),
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
              displayName:
                  _labelByPackage[packageName] ??
                  friendlyAppName(packageName, null),
            ),
        ]..sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
        );

    final applyToday = !_alreadyConfigured;

    try {
      final appsController = ref.read(monitoredAppsControllerProvider.notifier);
      final settingsController = ref.read(settingsControllerProvider.notifier);

      if (applyToday) {
        await appsController.applySelectionNow(apps);
        await settingsController.applyLimitNow(_minutes * 60);
      } else {
        final effectiveAt = nextLocalMidnight(DateTime.now());
        await appsController.scheduleSelection(apps);
        await settingsController.scheduleLimit(_minutes * 60, effectiveAt);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            applyToday
                ? 'Limit and apps saved'
                : 'Saved. Starts tomorrow at midnight.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } on Object catch (error) {
      debugPrint('Limit save failed: $error');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save your changes. Please try again."),
        ),
      );
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
              if (widget.settings.isLocked) ...[
                _LockedNotice(nextResetAt: widget.settings.nextResetAt),
                const SizedBox(height: 12),
              ] else if (_focusUntil != null) ...[
                _FocusLockedNotice(until: _focusUntil!),
                const SizedBox(height: 12),
              ],
              if (_hasPendingChange && !_locked) ...[
                _ScheduledNotice(
                  activeLimitSeconds: widget.settings.dailyLimitSeconds,
                  activeAppCount: _activeAppCount,
                ),
                const SizedBox(height: 12),
              ],
              LockoutSectionLabel(
                'Daily social limit',
                trailing: LockoutPill(
                  _locked ? 'Sealed' : 'Hard cap',
                  color: _locked ? LockoutPalette.coral : LockoutPalette.mint,
                  icon: _locked ? Icons.lock_outline : Icons.bolt,
                ),
              ),
              const SizedBox(height: 8),
              LockoutCardSurface(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                borderColor: LockoutPalette.mint.withValues(alpha: 0.2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    LockoutPalette.mint.withValues(alpha: 0.1),
                    LockoutPalette.surface,
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      formatDuration(_minutes * 60),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: LockoutPalette.mint,
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
                          : (value) => setState(() => _minutes = value.round()),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
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
                    const SizedBox(height: 10),
                    Text(
                      'Once a limit is active, changes begin at midnight.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LockoutSectionLabel(
                'Restricted apps',
                trailing: Text(
                  '${_selected.length} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search your apps',
                  isDense: true,
                ),
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
              ),
              const SizedBox(height: 8),
              for (final entry in _visibleApps)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: LockoutPalette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LockoutPalette.outline),
                  ),
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(entry.value),
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
              LockoutCardSurface(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const LockoutIconBadge(Icons.gpp_good_outlined, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Only the apps you choose count toward your limit. '
                        "Lockout doesn't track itself.",
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
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
                          : _alreadyConfigured
                          ? 'Save for tomorrow'
                          : 'Save changes',
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduledNotice extends StatelessWidget {
  const _ScheduledNotice({
    required this.activeLimitSeconds,
    required this.activeAppCount,
  });

  final int activeLimitSeconds;
  final int activeAppCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = activeLimitSeconds > 0
        ? '${formatDuration(activeLimitSeconds)} · $activeAppCount '
              '${activeAppCount == 1 ? 'app' : 'apps'}'
        : 'no limit';
    return LockoutCardSurface(
      padding: const EdgeInsets.all(15),
      borderColor: LockoutPalette.amber.withValues(alpha: 0.3),
      child: Row(
        children: [
          const LockoutIconBadge(
            Icons.schedule_outlined,
            color: LockoutPalette.amber,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'These changes start tomorrow at midnight. '
              "Today's limit is $today.",
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusLockedNotice extends StatelessWidget {
  const _FocusLockedNotice({required this.until});

  final DateTime until;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = until.difference(DateTime.now());
    return LockoutCardSurface(
      padding: const EdgeInsets.all(15),
      borderColor: LockoutPalette.coral.withValues(alpha: 0.34),
      child: Row(
        children: [
          const LockoutIconBadge(
            Icons.timer_outlined,
            color: LockoutPalette.coral,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'A focus lock is on until ${formatClockTime(until)} '
              '(${formatCountdown(remaining)}). '
              "You can't change the limit or apps yet.",
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
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
    return LockoutCardSurface(
      padding: const EdgeInsets.all(15),
      borderColor: LockoutPalette.coral.withValues(alpha: 0.34),
      child: Row(
        children: [
          const LockoutIconBadge(
            Icons.lock_outline,
            color: LockoutPalette.coral,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Locked until midnight (${formatCountdown(remaining)}). '
              "You can't change the limit or apps yet.",
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
