import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../core/widgets/lockout_ui.dart';
import '../../../domain/entities/reader_source.dart';
import 'reader_settings_controller.dart';

/// Chooses which sources feed Reader and which topics each source may use.
class ReaderSettingsScreen extends ConsumerWidget {
  const ReaderSettingsScreen({super.key});

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    String sourceId,
    bool enabled,
  ) async {
    try {
      await ref
          .read(readerSettingsControllerProvider.notifier)
          .setEnabled(sourceId, enabled);
    } on Object catch (error, stackTrace) {
      debugPrint('Reader source save failed: $error\n$stackTrace');
      if (!context.mounted) return;
      _showSaveError(context);
    }
  }

  Future<void> _toggleTopic(
    BuildContext context,
    WidgetRef ref,
    String sourceId,
    String topicId,
  ) async {
    try {
      await ref
          .read(readerSettingsControllerProvider.notifier)
          .toggleTopic(sourceId, topicId);
    } on Object catch (error, stackTrace) {
      debugPrint('Reader topic save failed: $error\n$stackTrace');
      if (!context.mounted) return;
      _showSaveError(context);
    }
  }

  void _showSaveError(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text("Couldn't save that change. Try again.")),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(readerSettingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'READER',
              style: theme.textTheme.labelSmall?.copyWith(
                color: LockoutPalette.mint,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 2),
            Text('Sources & topics', style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
      body: AppResumeObserver(
        onResume: () => ref.invalidate(readerSettingsControllerProvider),
        child: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            debugPrint('Reader settings load failed: $error');
            return ErrorRetryView(
              title: "Couldn't load Reader settings",
              message: 'Please try again.',
              onRetry: () => ref.invalidate(readerSettingsControllerProvider),
            );
          },
          data: (value) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _SettingsIntro(settings: value),
              const SizedBox(height: 18),
              LockoutSectionLabel(
                'Sources',
                trailing: Text(
                  '${value.enabledCount} of ${value.sources.length} on',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (value.sources.isEmpty)
                const LockoutEmptyState(
                  icon: Icons.rss_feed,
                  title: 'No sources available',
                  message:
                      'The bundled source catalogue is empty. Reinstall the '
                      'app to restore it.',
                )
              else
                for (final source in value.sources)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SourceCard(
                      source: source,
                      settings: value,
                      onEnabledChanged: (enabled) => unawaited(
                        _setEnabled(context, ref, source.id, enabled),
                      ),
                      onTopicToggled: (topicId) => unawaited(
                        _toggleTopic(context, ref, source.id, topicId),
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
              if (value.lastRefreshAt case final lastRefreshAt?)
                Text(
                  'Last refresh ${formatClockTime(lastRefreshAt)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Changes apply to the next background refresh. Reader only '
                'pulls new articles a few times a day, not every time you open '
                'it.',
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

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro({required this.settings});

  final ReaderSourceSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paused = settings.enabledCount == 0 && settings.sources.isNotEmpty;

    return LockoutCardSurface(
      borderColor: paused
          ? LockoutPalette.amber.withValues(alpha: 0.3)
          : LockoutPalette.outline,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LockoutIconBadge(
            paused ? Icons.pause_circle_outline : Icons.tune,
            color: paused ? LockoutPalette.amber : LockoutPalette.mint,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paused ? 'Reader is paused' : 'Choose what reaches you',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  paused
                      ? 'Every source is off. Turn one back on to fill the '
                            'daily list.'
                      : 'Only enabled sources are fetched. Topics narrow the '
                            'sources that support them.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.settings,
    required this.onEnabledChanged,
    required this.onTopicToggled,
  });

  final ReaderSource source;
  final ReaderSourceSettings settings;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onTopicToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = source.enabled ? LockoutPalette.mint : LockoutPalette.muted;
    final topicById = {
      for (final topic in settings.catalog.topics) topic.id: topic,
    };
    final availableTopics = [
      for (final topicId in settings.availableTopicsFor(source))
        ?topicById[topicId],
    ];
    final lastError = source.lastError?.trim();

    return LockoutCardSurface(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      borderColor: source.enabled
          ? LockoutPalette.mint.withValues(alpha: 0.18)
          : LockoutPalette.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LockoutIconBadge(_iconFor(source.kind), color: accent, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      _kindLabel(source.kind),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: source.enabled, onChanged: onEnabledChanged),
            ],
          ),
          if (availableTopics.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'TOPICS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final topic in availableTopics)
                  FilterChip(
                    label: Text(topic.label),
                    selected: source.topics.contains(topic.id),
                    onSelected: (_) => onTopicToggled(topic.id),
                  ),
              ],
            ),
          ],
          if (lastError != null && lastError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Last refresh: $lastError',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(ReaderSourceKind kind) {
    return switch (kind) {
      ReaderSourceKind.rss => Icons.rss_feed,
      ReaderSourceKind.hackerNews => Icons.terminal,
      ReaderSourceKind.devTo => Icons.code,
    };
  }

  String _kindLabel(ReaderSourceKind kind) {
    return switch (kind) {
      ReaderSourceKind.rss => 'RSS or Atom feed',
      ReaderSourceKind.hackerNews => 'Hacker News front page',
      ReaderSourceKind.devTo => 'dev.to articles',
    };
  }
}
