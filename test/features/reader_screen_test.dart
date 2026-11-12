import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/di.dart';
import 'package:lockout/core/theme/app_theme.dart';
import 'package:lockout/core/utils/day_window.dart';
import 'package:lockout/domain/entities/reader_feed.dart';
import 'package:lockout/domain/entities/reader_source.dart';
import 'package:lockout/domain/repositories/reader_repository.dart';
import 'package:lockout/domain/repositories/reader_source_repository.dart';
import 'package:lockout/domain/usecases/refresh_reader.dart';
import 'package:lockout/features/reader/presentation/reader_controller.dart';
import 'package:lockout/features/reader/presentation/reader_screen.dart';
import 'package:lockout/features/reader/presentation/reader_settings_screen.dart';

import '../helpers/fake_reader.dart';
import '../helpers/test_surface.dart';

void main() {
  final today = localDateKey(DateTime.now());

  const feedSource = ReaderSource(
    id: 'feed',
    name: 'Example Review',
    kind: ReaderSourceKind.rss,
    feedUrl: 'https://example.com/feed',
    siteUrl: 'https://example.com',
    enabled: true,
    topics: [],
    sortOrder: 0,
  );

  Future<void> pumpReader(
    WidgetTester tester, {
    required ReaderRepository reader,
    required ReaderSourceRepository sources,
    RefreshReader? refresh,
    Size? surfaceSize,
  }) async {
    if (surfaceSize == null) {
      useTallScreen(tester);
    } else {
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerRepositoryProvider.overrideWithValue(reader),
          readerSourceRepositoryProvider.overrideWithValue(sources),
          refreshReaderProvider.overrideWithValue(
            refresh ??
                RefreshReader(
                  repository: reader,
                  sources: sources,
                  clients: const <ReaderSourceKind, ReaderFeedClient>{},
                ),
          ),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const ReaderScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpSettings(
    WidgetTester tester, {
    required ReaderRepository reader,
    required ReaderSourceRepository sources,
  }) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerRepositoryProvider.overrideWithValue(reader),
          readerSourceRepositoryProvider.overrideWithValue(sources),
          refreshReaderProvider.overrideWithValue(
            RefreshReader(
              repository: reader,
              sources: sources,
              clients: const <ReaderSourceKind, ReaderFeedClient>{},
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ReaderSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renders the frozen daily list with attribution and reading time',
    (tester) async {
      final reader = FakeReaderRepository();
      reader.articles['quiet'] = readerArticle(
        id: 'quiet',
        title: 'The quiet web',
        sourceName: 'Example Review',
        excerpt: 'A slower kind of internet.',
        readingMinutes: 4,
      );
      reader.dailyPicks[today] = ['quiet'];
      final sources = FakeReaderSourceRepository(sources: const [feedSource]);

      await pumpReader(tester, reader: reader, sources: sources);

      expect(find.text("Today's reading"), findsOneWidget);
      expect(find.text('The quiet web'), findsOneWidget);
      expect(find.text('Example Review · 4 min read'), findsOneWidget);
      expect(find.text('1 PICK'), findsOneWidget);
      expect(find.text('1 left'), findsOneWidget);
    },
  );

  testWidgets('fits a narrow phone screen without overflow', (tester) async {
    final reader = FakeReaderRepository();
    reader.articles['tiny'] = readerArticle(
      id: 'tiny',
      title: 'A deliberately long article title that needs to wrap cleanly',
      sourceName: 'Example Review',
      excerpt:
          'A short excerpt that still needs enough room to wrap on a narrow '
          'phone without pushing the card sideways.',
      readingMinutes: 12,
    );
    reader.dailyPicks[today] = ['tiny'];
    final sources = FakeReaderSourceRepository(sources: const [feedSource]);

    await pumpReader(
      tester,
      reader: reader,
      sources: sources,
      surfaceSize: const Size(360, 800),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.text('A deliberately long article title that needs to wrap cleanly'),
      findsOneWidget,
    );
  });

  testWidgets('shows the final done state when every pick is read', (
    tester,
  ) async {
    final reader = FakeReaderRepository();
    reader.articles['done'] = readerArticle(
      id: 'done',
      title: 'Finished article',
      isRead: true,
    );
    reader.dailyPicks[today] = ['done'];
    final sources = FakeReaderSourceRepository(sources: const [feedSource]);

    await pumpReader(tester, reader: reader, sources: sources);

    expect(find.text("You're done for today"), findsOneWidget);
    expect(find.text('DONE'), findsOneWidget);
    expect(find.text('Finished article'), findsOneWidget);
  });

  testWidgets('shows an offline state when the cache is empty', (tester) async {
    final reader = FakeReaderRepository();
    final sources = FakeReaderSourceRepository(sources: const [feedSource]);
    final refresh = RefreshReader(
      repository: reader,
      sources: sources,
      clients: {
        ReaderSourceKind.rss: FakeReaderFeedClient(
          kind: ReaderSourceKind.rss,
          error: Exception('offline'),
        ),
      },
    );

    await pumpReader(
      tester,
      reader: reader,
      sources: sources,
      refresh: refresh,
    );

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('shows an empty state after a successful empty refresh', (
    tester,
  ) async {
    final reader = FakeReaderRepository();
    final sources = FakeReaderSourceRepository(sources: const [feedSource]);
    final refresh = RefreshReader(
      repository: reader,
      sources: sources,
      clients: {
        ReaderSourceKind.rss: FakeReaderFeedClient(kind: ReaderSourceKind.rss),
      },
    );

    await pumpReader(
      tester,
      reader: reader,
      sources: sources,
      refresh: refresh,
    );

    expect(find.text('No new articles yet'), findsOneWidget);
    expect(find.text('Manage sources'), findsOneWidget);
  });

  test('manual refresh respects the cooldown', () async {
    final reader = FakeReaderRepository();
    reader.articles['cached'] = readerArticle(id: 'cached');
    reader.dailyPicks[today] = ['cached'];
    final sources = FakeReaderSourceRepository(sources: const [feedSource]);
    sources.fetchedAt[feedSource.id] = DateTime.now();
    final refresh = RefreshReader(
      repository: reader,
      sources: sources,
      clients: const <ReaderSourceKind, ReaderFeedClient>{},
    );
    final container = ProviderContainer(
      overrides: [
        readerRepositoryProvider.overrideWithValue(reader),
        readerSourceRepositoryProvider.overrideWithValue(sources),
        refreshReaderProvider.overrideWithValue(refresh),
      ],
    );
    addTearDown(container.dispose);

    await container.read(readerControllerProvider.future);
    final outcome = await container
        .read(readerControllerProvider.notifier)
        .refresh();

    expect(outcome.kind, ReaderRefreshKind.cooldown);
    expect(outcome.cooldownRemaining, greaterThan(Duration.zero));
  });

  testWidgets('settings persist source switches and topic filters', (
    tester,
  ) async {
    const source = ReaderSource(
      id: 'feed',
      name: 'Example Review',
      kind: ReaderSourceKind.rss,
      siteUrl: 'https://example.com',
      enabled: true,
      topics: [],
      sortOrder: 0,
    );
    const catalog = ReaderSourceCatalog(
      topics: [
        ReaderTopic(id: 'technology', label: 'Technology'),
        ReaderTopic(id: 'design', label: 'Design'),
      ],
      sources: [
        ReaderSourceDefinition(
          id: 'feed',
          name: 'Example Review',
          kind: ReaderSourceKind.rss,
          siteUrl: 'https://example.com',
          enabled: true,
          defaultTopics: [],
          availableTopics: ['technology', 'design'],
          sortOrder: 0,
        ),
      ],
    );
    final sources = FakeReaderSourceRepository(
      sources: const [source],
      catalog: catalog,
    );

    await pumpSettings(
      tester,
      reader: FakeReaderRepository(),
      sources: sources,
    );

    expect(find.text('Example Review'), findsOneWidget);
    expect(find.text('Technology'), findsOneWidget);
    expect(find.text('Design'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect((await sources.loadSources()).single.enabled, isFalse);
    expect(find.text('Reader is paused'), findsOneWidget);

    await tester.tap(find.text('Design'));
    await tester.pumpAndSettle();
    expect((await sources.loadSources()).single.topics, contains('design'));
  });
}
