import 'reader_source.dart';

/// A normalised item returned by one remote source client.
class ReaderFeedItem {
  const ReaderFeedItem({
    required this.title,
    required this.url,
    this.excerpt = '',
    this.contentHtml,
    this.publishedAt,
  });

  final String title;
  final String url;
  final String excerpt;
  final String? contentHtml;
  final DateTime? publishedAt;
}

class ReaderFeedResult {
  const ReaderFeedResult({required this.items, this.etag, this.lastModified});

  final List<ReaderFeedItem> items;
  final String? etag;
  final String? lastModified;
}

/// Network port used by [RefreshReader].
///
/// Implementations live in `data/reader`; the domain stays free of dio, RSS and
/// Android types.
abstract interface class ReaderFeedClient {
  ReaderSourceKind get kind;

  Future<ReaderFeedResult> fetch(ReaderSource source);
}

class ReaderRefreshFailure {
  const ReaderRefreshFailure({required this.sourceId, required this.message});

  final String sourceId;
  final String message;
}

class ReaderRefreshResult {
  const ReaderRefreshResult({
    required this.fetchedArticles,
    required this.failures,
  });

  final int fetchedArticles;
  final List<ReaderRefreshFailure> failures;

  bool get succeeded => failures.isEmpty;

  bool get hasAnyFailure => failures.isNotEmpty;
}
