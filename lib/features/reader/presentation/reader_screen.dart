import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../core/widgets/lockout_ui.dart';
import '../../../domain/entities/reader_article.dart';
import 'reader_controller.dart';
import 'reader_settings_screen.dart';

/// The Reader tab: one finite list of articles for today.
class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key});

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final outcome = await ref.read(readerControllerProvider.notifier).refresh();
    if (!context.mounted) return;

    final result = outcome.result;
    final message = switch (outcome.kind) {
      ReaderRefreshKind.busy => null,
      ReaderRefreshKind.cooldown =>
        'Checked recently. Try again in '
            '${formatCountdown(outcome.cooldownRemaining)}.',
      ReaderRefreshKind.failed =>
        "Couldn't refresh. Showing the articles already saved on this phone.",
      ReaderRefreshKind.refreshed =>
        result != null && result.hasAnyFailure
            ? 'Updated, but some sources could not be reached.'
            : 'Reading list updated.',
    };
    if (message == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSettings(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReaderSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reader = ref.watch(readerControllerProvider);
    final day = reader.value;
    final isBusy = reader.isLoading || (day?.isRefreshing ?? false);

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
            Text('Reader', style: theme.textTheme.headlineSmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh reading list',
            onPressed: isBusy ? null : () => unawaited(_refresh(context, ref)),
            icon: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Reader settings',
            onPressed: () => unawaited(_openSettings(context)),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: AppResumeObserver(
        onResume: () => ref.invalidate(readerControllerProvider),
        child: reader.when(
          loading: () => const _ReaderLoading(),
          error: (error, _) {
            debugPrint('Reader load failed: $error');
            return ErrorRetryView(
              title: "Couldn't load the Reader",
              message: 'Please try again.',
              onRetry: () => ref.invalidate(readerControllerProvider),
            );
          },
          data: (value) => RefreshIndicator(
            onRefresh: () => _refresh(context, ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _ReaderHero(day: value),
                if (value.isOffline) ...[
                  const SizedBox(height: 12),
                  _OfflineCard(
                    onRetry: () => unawaited(_refresh(context, ref)),
                    onSettings: () => unawaited(_openSettings(context)),
                  ),
                ] else if (value.isEmpty) ...[
                  const SizedBox(height: 12),
                  _EmptyCard(
                    onSettings: () => unawaited(_openSettings(context)),
                  ),
                ] else ...[
                  if (value.hasRefreshWarning) ...[
                    const SizedBox(height: 12),
                    const _RefreshWarning(),
                  ],
                  const SizedBox(height: 16),
                  LockoutSectionLabel(
                    value.isDone ? "Today's list" : 'Up next',
                    trailing: Text(
                      value.isDone
                          ? '${value.readCount} read'
                          : '${value.unreadCount} left',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final article in value.picks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ArticleCard(article: article),
                    ),
                ],
                const SizedBox(height: 18),
                Text(
                  'One short list a day. Reader updates in the background a '
                  'few times a day, never while you scroll.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderLoading extends StatelessWidget {
  const _ReaderLoading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Gathering today\'s reading',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'This only happens when the cache is empty.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderHero extends StatelessWidget {
  const _ReaderHero({required this.day});

  final ReaderDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastRefreshAt = day.lastRefreshAt;

    return LockoutCardSurface(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          LockoutPalette.mintDeep.withValues(alpha: 0.6),
          LockoutPalette.surface,
        ],
      ),
      borderColor: LockoutPalette.mint.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LockoutIconBadge(Icons.menu_book_outlined),
              const Spacer(),
              LockoutPill(
                day.isDone
                    ? 'Done'
                    : '${day.picks.length} '
                          '${day.picks.length == 1 ? 'pick' : 'picks'}',
                icon: day.isDone ? Icons.check : Icons.auto_stories_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            day.isDone ? "You're done for today" : "Today's reading",
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            day.isDone
                ? "That's the whole list. Nothing new will appear until "
                      'tomorrow.'
                : 'A short, finite list. No infinite scroll, no autoplay, '
                      'no next-up loop.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ReaderStat(
                  value: day.isDone ? '${day.readCount}' : '${day.unreadCount}',
                  label: day.isDone ? 'read' : 'left',
                ),
              ),
              const _StatDivider(),
              Expanded(
                child: _ReaderStat(
                  value: '${day.totalMinutes}m',
                  label: 'to read',
                ),
              ),
              const _StatDivider(),
              Expanded(
                child: _ReaderStat(
                  value: formatDuration(day.readingSeconds),
                  label: 'read today',
                ),
              ),
            ],
          ),
          if (lastRefreshAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last updated ${formatClockTime(lastRefreshAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReaderStat extends StatelessWidget {
  const _ReaderStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            letterSpacing: 1,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: LockoutPalette.outline,
    );
  }
}

class _OfflineCard extends StatelessWidget {
  const _OfflineCard({required this.onRetry, required this.onSettings});

  final VoidCallback onRetry;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return LockoutEmptyState(
      icon: Icons.cloud_off_outlined,
      title: "You're offline",
      message:
          "Today's list isn't saved yet. Connect to the internet, then "
          'try again.',
      action: Wrap(
        spacing: 4,
        children: [
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try again'),
          ),
          TextButton(
            onPressed: onSettings,
            child: const Text('Manage sources'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return LockoutEmptyState(
      icon: Icons.inbox_outlined,
      title: 'No new articles yet',
      message:
          'Reader updates a few times a day. Try again later, or choose '
          'different sources and topics.',
      action: TextButton(
        onPressed: onSettings,
        child: const Text('Manage sources'),
      ),
    );
  }
}

class _RefreshWarning extends StatelessWidget {
  const _RefreshWarning();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LockoutCardSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: LockoutPalette.amber.withValues(alpha: 0.3),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: LockoutPalette.amber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Some sources couldn't update. The articles already saved are "
              'still here.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: LockoutPalette.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final ReaderArticle article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excerpt = article.excerpt.trim();

    return LockoutCardSurface(
      padding: const EdgeInsets.all(16),
      color: article.isRead
          ? LockoutPalette.surface.withValues(alpha: 0.7)
          : LockoutPalette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.isRead) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: LockoutPalette.mint,
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Expanded(
                child: Text(
                  article.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: article.isRead
                        ? theme.colorScheme.onSurfaceVariant
                        : LockoutPalette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${article.sourceName} · ${article.readingMinutes} min read',
            style: theme.textTheme.bodySmall?.copyWith(
              color: LockoutPalette.mint,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (excerpt.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              excerpt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
