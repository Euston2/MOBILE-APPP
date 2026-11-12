import '../entities/reader_article.dart';
import '../entities/reader_feed.dart';
import '../entities/reader_source.dart';
import '../repositories/reader_repository.dart';
import '../repositories/reader_source_repository.dart';
import 'reader_url.dart';
import 'reading_time.dart';

/// Refreshes every enabled source, then stores the normalised result.
///
/// Source failures are isolated and reported individually. One broken feed must
/// never stop the rest of the Reader from updating.
class RefreshReader {
  RefreshReader({
    required this.repository,
    required this.sources,
    required this.clients,
    DateTime Function()? now,
    this.retention = const Duration(days: 30),
  }) : _now = now ?? DateTime.now;

  final ReaderRepository repository;
  final ReaderSourceRepository sources;
  final Map<ReaderSourceKind, ReaderFeedClient> clients;
  final DateTime Function() _now;
  final Duration retention;

  Future<ReaderRefreshResult> call() async {
    final now = _now();
    final configured = await sources.loadSources();
    final enabled = configured.where((source) => source.enabled).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    var fetched = 0;
    final failures = <ReaderRefreshFailure>[];

    for (final source in enabled) {
      final client = clients[source.kind];
      if (client == null) {
        failures.add(
          ReaderRefreshFailure(
            sourceId: source.id,
            message: 'No client is configured for ${source.kind.name}.',
          ),
        );
        continue;
      }

      try {
        final result = await client.fetch(source);
        final articles = _normalize(result.items, source, now);
        if (articles.isNotEmpty) {
          await repository.saveFetched(articles);
        }
        await sources.markFetched(
          sourceId: source.id,
          at: now,
          etag: result.etag,
          lastModified: result.lastModified,
        );
        fetched += articles.length;
      } on Object catch (error) {
        final message = _shortError(error);
        failures.add(
          ReaderRefreshFailure(sourceId: source.id, message: message),
        );
        await sources.markFetchFailed(sourceId: source.id, error: message);
      }
    }

    await repository.pruneBefore(now.subtract(retention));
    return ReaderRefreshResult(
      fetchedArticles: fetched,
      failures: List.unmodifiable(failures),
    );
  }

  List<ReaderArticle> _normalize(
    Iterable<ReaderFeedItem> items,
    ReaderSource source,
    DateTime now,
  ) {
    final seen = <String>{};
    final articles = <ReaderArticle>[];

    for (final item in items) {
      final title = item.title.trim();
      final canonicalUrl = canonicalizeReaderUrl(_resolveUrl(item.url, source));
      if (title.isEmpty || canonicalUrl == null) continue;

      final id = readerArticleId(canonicalUrl);
      if (!seen.add(id)) continue;

      final content = _cleanContent(item.contentHtml);
      final excerpt = item.excerpt.trim().isNotEmpty
          ? plainTextPreview(item.excerpt)
          : plainTextPreview(content);
      if (excerpt.isEmpty && content == null) continue;

      articles.add(
        ReaderArticle(
          id: id,
          sourceId: source.id,
          sourceName: source.name,
          title: title,
          url: canonicalUrl,
          excerpt: excerpt,
          contentHtml: content,
          readingMinutes: estimateReadingMinutes(content ?? excerpt),
          publishedAt: item.publishedAt,
          fetchedAt: now,
        ),
      );
    }

    return articles;
  }

  String _resolveUrl(String raw, ReaderSource source) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.hasScheme) return raw;
    final base = Uri.tryParse(source.siteUrl);
    if (base == null) return raw;
    return base.resolveUri(uri).toString();
  }

  String? _cleanContent(String? html) {
    final value = html?.trim();
    if (value == null || value.isEmpty) return null;
    return estimateReadingMinutes(value) >= 2 ? value : null;
  }

  String _shortError(Object error) {
    final text = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= 240) return text;
    return '${text.substring(0, 240)}…';
  }
}
