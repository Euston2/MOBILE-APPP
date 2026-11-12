import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/data/local/app_database.dart';
import 'package:lockout/data/local/daos/reader_dao.dart';
import 'package:lockout/data/reader/reader_source_catalog.dart';
import 'package:lockout/data/repositories/drift_reader_source_repository.dart';
import 'package:lockout/domain/entities/reader_source.dart';

class _FakeCatalogLoader extends ReaderSourceCatalogLoader {
  _FakeCatalogLoader(this.value);

  ReaderSourceCatalog value;

  @override
  Future<ReaderSourceCatalog> load({AssetBundle? bundle}) async => value;
}

void main() {
  late AppDatabase database;
  late ReaderDao dao;
  late _FakeCatalogLoader loader;
  late DriftReaderSourceRepository repository;

  ReaderSourceDefinition definition({
    String name = 'Example',
    bool enabled = true,
    List<String> defaultTopics = const ['technology'],
  }) {
    return ReaderSourceDefinition(
      id: 'example',
      name: name,
      kind: ReaderSourceKind.rss,
      feedUrl: 'https://example.com/feed.xml',
      siteUrl: 'https://example.com',
      enabled: enabled,
      defaultTopics: defaultTopics,
      availableTopics: const ['technology', 'android'],
      sortOrder: 0,
    );
  }

  setUp(() {
    database = AppDatabase.memory();
    dao = ReaderDao(database);
    loader = _FakeCatalogLoader(
      ReaderSourceCatalog(
        topics: const [
          ReaderTopic(id: 'technology', label: 'Technology'),
          ReaderTopic(id: 'android', label: 'Android'),
        ],
        sources: [definition()],
      ),
    );
    repository = DriftReaderSourceRepository(dao, loader);
  });

  tearDown(() => database.close());

  test(
    'seeds the catalogue once and preserves user choices on resync',
    () async {
      var sources = await repository.loadSources();
      expect(sources, hasLength(1));
      expect(sources.single.name, 'Example');
      expect(sources.single.enabled, isTrue);
      expect(sources.single.topics, ['technology']);

      await repository.setEnabled('example', false);
      await repository.setTopics('example', ['android']);

      loader.value = ReaderSourceCatalog(
        topics: loader.value.topics,
        sources: [
          definition(
            name: 'Renamed source',
            enabled: true,
            defaultTopics: ['technology'],
          ),
        ],
      );
      sources = await repository.loadSources();

      expect(sources.single.name, 'Renamed source');
      expect(sources.single.enabled, isFalse);
      expect(sources.single.topics, ['android']);
    },
  );

  test('records successful and failed refreshes', () async {
    await repository.loadSources();
    final at = DateTime(2026, 11, 12, 9, 30);

    await repository.markFetched(sourceId: 'example', at: at);
    expect(await repository.lastRefreshAt(), at);

    await repository.markFetchFailed(sourceId: 'example', error: 'offline');
    final source = (await repository.loadSources()).single;
    expect(source.lastError, 'offline');
    expect(await repository.lastRefreshAt(), at);

    await repository.markFetched(sourceId: 'example', at: at);
    expect((await repository.loadSources()).single.lastError, isNull);
  });
}
