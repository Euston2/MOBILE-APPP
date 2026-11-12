import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_resume_observer.dart';
import '../../../core/widgets/lockout_ui.dart';
import '../../../domain/entities/reader_article.dart';
import 'reader_article_card.dart';
import 'reader_article_screen.dart';
import 'reader_controller.dart';

/// Saved articles that survive the daily list rolling over.
class ReaderBookmarksScreen extends ConsumerWidget {
  const ReaderBookmarksScreen({super.key});

  Future<void> _openArticle(
    BuildContext context,
    WidgetRef ref,
    ReaderArticle article,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderArticleScreen(article: article),
      ),
    );
    if (!context.mounted) return;
    ref.invalidate(readerBookmarksProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bookmarks = ref.watch(readerBookmarksProvider);

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
            Text('Bookmarks', style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
      body: bookmarks.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
        error: (error, _) {
          debugPrint('Reader bookmarks failed: $error');
          return ErrorRetryView(
            title: "Couldn't load bookmarks",
            message: 'Please try again.',
            onRetry: () => ref.invalidate(readerBookmarksProvider),
          );
        },
        data: (items) {
          if (items.isEmpty) {
            return _EmptyBookmarks(onBack: () => Navigator.of(context).pop());
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Saved for later. These stay here until you remove the '
                    'bookmark.',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }
              final article = items[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReaderArticleCard(
                  article: article,
                  onTap: () => unawaited(_openArticle(context, ref, article)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyBookmarks extends StatelessWidget {
  const _EmptyBookmarks({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LockoutCardSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LockoutIconBadge(
                Icons.bookmark_border,
                color: LockoutPalette.muted,
              ),
              const SizedBox(height: 14),
              Text(
                'Nothing saved yet',
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Open an article and tap the bookmark to keep it here. '
                'Bookmarks are never overwritten by a refresh.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onBack,
                child: const Text('Back to today'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
