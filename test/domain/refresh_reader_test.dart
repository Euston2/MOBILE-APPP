import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/entities/reader_feed.dart';
import 'package:lockout/domain/entities/reader_source.dart';
import 'package:lockout/domain/usecases/reader_url.dart';
import 'package:lockout/domain/usecases/refresh_reader.dart';

import '../helpers/fake_reader.dart';

void main() {
  late FakeReaderRepository repository;
  late FakeReaderSourceRepository sources;
  late DateTime now;

  final rssSource = ReaderSource(
    id: 'rss',
    name: 'Example RSS',
    kind: ReaderSourceKind.rss,
    feedUrl: 'https://example.com/feed.xml',
    siteUrl: 'https://example.com',
    enabled: true,
    topics: const [],
    sortOrder: 0,
  );
  final devToSource = ReaderSource(
    id: 'devto',
    name: 'dev.to',
    kind: ReaderSourceKind.devTo,
    feedUrl: 'https://dev.to/api/articles',
    siteUrl: 'https://dev.to',
    enabled: true,
    topics: const ['flutter'],
    sortOrder: 1,
  );
  final disabledSource = ReaderSource(
    id: 'disabled',
    name: 'Disabled',
    kind: ReaderSourceKind.rss,
    feedUrl: 'https://example.com/disabled.xml',
    siteUrl: 'https://example.com',
    enabled: false,
    topics: const [],
    sortOrder: 2,
  );

  setUp(() {
    now = DateTime(2026, 11, 12, 9, 30);
    repository = FakeReaderRepository();
    sources = FakeReaderSourceRepository(
      sources: [rssSource, devToSource, disabledSource],
    );
  });

  test('normalises items, isolates failures and prunes old cache', () async {
    final rss = FakeReaderFeedClient(
      kind: ReaderSourceKind.rss,
      result: const ReaderFeedResult(
        items: [
          ReaderFeedItem(
            title: 'First story',
            url: 'https://www.example.com/story/?utm_source=feed&id=7#top',
            excerpt: 'A short summary.',
          ),
          ReaderFeedItem(
            title: 'Duplicate story',
            url: 'https://example.com/story?id=7',
            excerpt: 'Duplicate copy.',
          ),
          ReaderFeedItem(
            title: 'Social post',
            url: 'https://twitter.com/example/status/1',
            excerpt: 'Not a Reader item.',
          ),
          ReaderFeedItem(title: ' ', url: 'https://example.com/empty-title'),
          ReaderFeedItem(
            title: 'Not a web URL',
            url: 'mailto:hello@example.com',
          ),
        ],
        etag: '"abc"',
      ),
    );
    final devTo = FakeReaderFeedClient(
      kind: ReaderSourceKind.devTo,
      error: StateError('offline'),
    );
    final disabled = FakeReaderFeedClient(
      kind: ReaderSourceKind.rss,
      result: const ReaderFeedResult(items: []),
    );
    final refresh = RefreshReader(
      repository: repository,
      sources: sources,
      clients: {ReaderSourceKind.rss: rss, ReaderSourceKind.devTo: devTo},
      now: () => now,
    );

    final result = await refresh();

    expect(result.fetchedArticles, 1);
    expect(result.failures, hasLength(1));
    expect(result.failures.single.sourceId, 'devto');
    expect(rss.calls, 1);
    expect(devTo.calls, 1);
    expect(disabled.calls, 0);

    final article = repository.savedBatches.single.single;
    expect(article.url, 'https://example.com/story?id=7');
    expect(article.id, readerArticleId(article.url));
    expect(article.title, 'First story');
    expect(article.sourceId, 'rss');
    expect(article.sourceName, 'Example RSS');
    expect(article.excerpt, 'A short summary.');
    expect(article.contentHtml, isNull);
    expect(article.readingMinutes, 1);
    expect(article.fetchedAt, now);
    expect(article.isRead, isFalse);

    expect(sources.fetchedAt['rss'], now);
    expect(sources.failures['devto'], contains('offline'));
    expect(repository.prunedBefore, now.subtract(const Duration(days: 30)));
  });

  test('caches long feed content and estimates its reading time', () async {
    final longHtml = '<p>${List.filled(250, 'word').join(' ')}</p>';
    final rss = FakeReaderFeedClient(
      kind: ReaderSourceKind.rss,
      result: ReaderFeedResult(
        items: [
          ReaderFeedItem(
            title: 'Long read',
            url: 'https://example.com/long',
            excerpt: 'Summary',
            contentHtml: longHtml,
          ),
        ],
      ),
    );
    final refresh = RefreshReader(
      repository: repository,
      sources: FakeReaderSourceRepository(sources: [rssSource]),
      clients: {ReaderSourceKind.rss: rss},
      now: () => now,
    );

    final result = await refresh();

    expect(result.fetchedArticles, 1);
    final article = repository.savedBatches.single.single;
    expect(article.contentHtml, longHtml);
    expect(article.readingMinutes, 2);
  });

  test('resolves relative feed links against the source site', () async {
    final rss = FakeReaderFeedClient(
      kind: ReaderSourceKind.rss,
      result: const ReaderFeedResult(
        items: [
          ReaderFeedItem(
            title: 'Relative link',
            url: '/relative-story',
            excerpt: 'Summary',
          ),
        ],
      ),
    );
    final refresh = RefreshReader(
      repository: repository,
      sources: FakeReaderSourceRepository(sources: [rssSource]),
      clients: {ReaderSourceKind.rss: rss},
      now: () => now,
    );

    await refresh();

    expect(
      repository.savedBatches.single.single.url,
      'https://example.com/relative-story',
    );
  });

  test('succeeds with no enabled sources', () async {
    final refresh = RefreshReader(
      repository: repository,
      sources: FakeReaderSourceRepository(sources: [disabledSource]),
      clients: const {},
      now: () => now,
    );

    final result = await refresh();

    expect(result.fetchedArticles, 0);
    expect(result.failures, isEmpty);
    expect(repository.savedBatches, isEmpty);
    expect(repository.prunedBefore, now.subtract(const Duration(days: 30)));
  });
}
