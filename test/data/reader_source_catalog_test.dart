import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/data/reader/reader_source_catalog.dart';
import 'package:lockout/domain/entities/reader_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the bundled source catalogue', () async {
    final catalog = await const ReaderSourceCatalogLoader().load();

    expect(catalog.topics.length, greaterThanOrEqualTo(20));
    expect(catalog.sources.length, greaterThanOrEqualTo(20));
    expect(catalog.sources.map((source) => source.id), contains('hacker-news'));
    expect(catalog.sources.map((source) => source.id), contains('devto'));
    expect(catalog.sources.map((source) => source.id), contains('bbc-world'));
    expect(catalog.sources.map((source) => source.id), contains('aeon'));

    final topicIds = {for (final topic in catalog.topics) topic.id};
    for (final source in catalog.sources) {
      expect(
        source.availableTopics,
        isNotEmpty,
        reason: '${source.id} should advertise at least one topic',
      );
      expect(
        topicIds.containsAll(source.availableTopics),
        isTrue,
        reason: '${source.id} has an unknown available topic',
      );
      expect(
        topicIds.containsAll(source.defaultTopics),
        isTrue,
        reason: '${source.id} has an unknown default topic',
      );
    }
  });

  test('parses topics and sources, filtering unknown topics and kinds', () {
    final catalog = const ReaderSourceCatalogLoader().parse({
      'topics': [
        {'id': 'technology', 'label': 'Technology'},
        {'id': 'android', 'label': 'Android'},
      ],
      'sources': [
        {
          'id': 'hn',
          'name': 'Hacker News',
          'kind': 'hackerNews',
          'siteUrl': 'https://news.ycombinator.com',
          'feedUrl': 'https://hacker-news.firebaseio.com/v0/topstories.json',
          'availableTopics': ['technology', 'unknown'],
          'defaultTopics': ['technology'],
          'sortOrder': 0,
        },
        {
          'id': 'bad',
          'name': 'Bad kind',
          'kind': 'podcast',
          'siteUrl': 'https://example.com',
        },
        {
          'id': 'android',
          'name': 'Android',
          'kind': 'rss',
          'siteUrl': 'https://android.example.com',
          'feedUrl': 'https://android.example.com/feed.xml',
          'availableTopics': ['android'],
          'defaultTopics': ['android'],
          'enabled': false,
        },
      ],
    });

    expect(catalog.topics.map((topic) => topic.id), ['technology', 'android']);
    expect(catalog.sources, hasLength(2));
    expect(catalog.sources.first.id, 'hn');
    expect(catalog.sources.first.kind, ReaderSourceKind.hackerNews);
    expect(catalog.sources.first.availableTopics, ['technology']);
    expect(catalog.sources.first.defaultTopics, ['technology']);
    expect(catalog.sources.last.id, 'android');
    expect(catalog.sources.last.enabled, isFalse);
    expect(catalog.sources.last.sortOrder, 1);
    expect(catalog.topicLabels(['android', 'technology']), [
      'Android',
      'Technology',
    ]);
  });

  test('skips malformed source entries without failing the catalogue', () {
    final catalog = const ReaderSourceCatalogLoader().parse({
      'topics': [
        {'id': 'technology', 'label': 'Technology'},
      ],
      'sources': [
        {
          'id': '',
          'name': 'No id',
          'kind': 'rss',
          'siteUrl': 'https://example.com',
        },
        {
          'id': 'missing-name',
          'name': '',
          'kind': 'rss',
          'siteUrl': 'https://example.com',
        },
        {
          'id': 'ok',
          'name': 'Okay',
          'kind': 'rss',
          'siteUrl': 'https://example.com',
          'feedUrl': 'https://example.com/feed.xml',
        },
      ],
    });

    expect(catalog.sources, hasLength(1));
    expect(catalog.sources.single.id, 'ok');
  });
}
