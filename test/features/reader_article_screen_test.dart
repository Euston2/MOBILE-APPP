import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/di.dart';
import 'package:lockout/core/theme/app_theme.dart';
import 'package:lockout/domain/entities/reader_source.dart';
import 'package:lockout/features/reader/presentation/reader_article_screen.dart';

import '../helpers/fake_reader.dart';
import '../helpers/test_surface.dart';

void main() {
  const source = ReaderSource(
    id: 'source',
    name: 'Example Review',
    kind: ReaderSourceKind.rss,
    feedUrl: 'https://example.com/feed',
    siteUrl: 'https://example.com',
    enabled: true,
    topics: [],
    sortOrder: 0,
  );

  Future<void> pumpArticle(
    WidgetTester tester, {
    required FakeReaderRepository reader,
    required FakeReaderSourceRepository sources,
    required String id,
  }) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerRepositoryProvider.overrideWithValue(reader),
          readerSourceRepositoryProvider.overrideWithValue(sources),
          readerContentExtractionEnabledProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: ReaderArticleScreen(article: reader.articles[id]!),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders cached article content and marks it read', (
    tester,
  ) async {
    final reader = FakeReaderRepository();
    reader.articles['article'] = readerArticle(
      id: 'article',
      title: 'The quiet web',
      sourceName: 'Example Review',
      excerpt: 'A slower kind of internet.',
      contentHtml: '<p>A slower kind of internet, saved for reading.</p>',
      readingMinutes: 4,
    );
    final sources = FakeReaderSourceRepository(sources: const [source]);

    await pumpArticle(tester, reader: reader, sources: sources, id: 'article');

    expect(find.text('The quiet web'), findsOneWidget);
    expect(
      find.text(
        'A slower kind of internet, saved for reading.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text('Example Review · 4 min read'), findsOneWidget);
    expect(find.text('example.com'), findsOneWidget);
    expect(find.text('Open original'), findsOneWidget);
    expect(reader.articles['article']!.isRead, isTrue);
  });

  testWidgets('toggles a bookmark and persists it', (tester) async {
    final reader = FakeReaderRepository();
    reader.articles['article'] = readerArticle(
      id: 'article',
      sourceName: 'Example Review',
      contentHtml: '<p>Saved words.</p>',
    );
    final sources = FakeReaderSourceRepository(sources: const [source]);

    await pumpArticle(tester, reader: reader, sources: sources, id: 'article');

    await tester.tap(find.byTooltip('Bookmark article'));
    await tester.pumpAndSettle();

    expect(reader.articles['article']!.isBookmarked, isTrue);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    expect(find.byTooltip('Remove bookmark'), findsOneWidget);
  });

  testWidgets('falls back to the excerpt when full text is unavailable', (
    tester,
  ) async {
    final reader = FakeReaderRepository();
    reader.articles['article'] = readerArticle(
      id: 'article',
      sourceName: 'Example Review',
      excerpt: 'The feed only included this teaser.',
    );
    final sources = FakeReaderSourceRepository(sources: const [source]);

    await pumpArticle(tester, reader: reader, sources: sources, id: 'article');

    expect(find.text('The feed only included this teaser.'), findsOneWidget);
    expect(find.text('Full article not saved'), findsOneWidget);
    expect(find.text('Open original'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
