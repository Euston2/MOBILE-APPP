import '../entities/reader_article.dart';
import 'reader_url.dart';

/// Source id/name used for links the user adds themselves.
///
/// Keeping these in the domain makes it cheap to tell a curated pick from a
/// personal one without a schema change.
const String customReaderSourceId = 'custom-links';
const String customReaderSourceName = 'Your links';

/// The finite daily list still tops out here, even when the user adds links.
const int maxDailyReaderPicks = 10;

/// Builds a cached article from a URL the user pasted.
///
/// Returns null for anything the Reader must not open (social hosts, non-web
/// URLs, opaque strings). The article has no extracted body yet; the article
/// screen can try Readability and otherwise offers the original page.
ReaderArticle? buildCustomReaderArticle({
  required String url,
  String? title,
  DateTime? now,
}) {
  final canonical = canonicalizeReaderUrl(url);
  if (canonical == null) return null;

  final uri = Uri.parse(canonical);
  final suppliedTitle = title?.trim();
  final articleTitle = suppliedTitle == null || suppliedTitle.isEmpty
      ? _titleFor(uri)
      : suppliedTitle;

  final at = now ?? DateTime.now();
  return ReaderArticle(
    id: readerArticleId(canonical),
    sourceId: customReaderSourceId,
    sourceName: customReaderSourceName,
    title: articleTitle,
    url: canonical,
    excerpt: 'Saved by you · ${uri.host}',
    readingMinutes: 1,
    fetchedAt: at,
  );
}

String _titleFor(Uri uri) {
  final segments = uri.pathSegments.where((part) => part.trim().isNotEmpty);
  if (segments.isEmpty) return uri.host;

  final raw = Uri.decodeComponent(segments.last);
  final cleaned = raw
      .replaceAll(RegExp(r'[-_+]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty || cleaned.length > 90) return uri.host;

  // A slug such as "the-quiet-web" is useful; a bare id or "index.html" is
  // not, so fall back to the host when there are not at least two words.
  final words = cleaned
      .split(' ')
      .where((word) => RegExp(r'[A-Za-z]').hasMatch(word));
  if (words.length < 2) return uri.host;

  return cleaned[0].toUpperCase() + cleaned.substring(1);
}
