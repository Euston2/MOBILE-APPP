import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/usecases/custom_reader_link.dart';
import 'package:lockout/domain/usecases/reader_url.dart';

void main() {
  test('builds a stable personal article from a web URL', () {
    final at = DateTime(2026, 11, 16, 9, 30);
    final first = buildCustomReaderArticle(
      url: 'https://example.com/the-quiet-web',
      now: at,
    );
    final second = buildCustomReaderArticle(
      url: 'https://example.com/the-quiet-web',
      now: at.add(const Duration(minutes: 1)),
    );

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(first!.id, second!.id);
    expect(first.id, readerArticleId('https://example.com/the-quiet-web'));
    expect(first.sourceId, customReaderSourceId);
    expect(first.sourceName, customReaderSourceName);
    expect(first.title, 'The quiet web');
    expect(first.url, 'https://example.com/the-quiet-web');
    expect(first.readingMinutes, 1);
    expect(first.fetchedAt, at);
  });

  test('uses a supplied title and strips tracking parameters', () {
    final article = buildCustomReaderArticle(
      url: 'https://example.com/post?utm_source=newsletter&id=7',
      title: '  My saved read  ',
    );

    expect(article, isNotNull);
    expect(article!.title, 'My saved read');
    expect(article.url, 'https://example.com/post?id=7');
    expect(article.id, readerArticleId(article.url));
  });

  test('falls back to the host for bare paths', () {
    final article = buildCustomReaderArticle(
      url: 'https://example.com/index.html',
    );

    expect(article, isNotNull);
    expect(article!.title, 'example.com');
  });

  test('rejects social, non-web and empty links', () {
    expect(buildCustomReaderArticle(url: ''), isNull);
    expect(
      buildCustomReaderArticle(url: 'https://instagram.com/p/123'),
      isNull,
    );
    expect(buildCustomReaderArticle(url: 'ftp://example.com/a'), isNull);
    expect(buildCustomReaderArticle(url: 'not a url'), isNull);
  });
}
