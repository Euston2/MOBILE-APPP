import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lockout_ui.dart';
import '../../../domain/entities/reader_article.dart';

/// Compact article row shared by the daily list and saved bookmarks.
class ReaderArticleCard extends StatelessWidget {
  const ReaderArticleCard({
    required this.article,
    required this.onTap,
    this.onRemove,
    super.key,
  });

  final ReaderArticle article;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excerpt = article.excerpt.trim();

    return LockoutCardSurface(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
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
              if (article.isBookmarked) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.bookmark,
                  size: 16,
                  color: LockoutPalette.mint,
                ),
              ],
              if (onRemove case final onRemove?) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: "Remove from today's list",
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 16),
                ),
              ],
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
