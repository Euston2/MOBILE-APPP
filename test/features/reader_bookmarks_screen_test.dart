import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/di.dart';
import 'package:lockout/core/theme/app_theme.dart';
import 'package:lockout/domain/entities/reader_source.dart';
import 'package:lockout/features/reader/presentation/reader_article_screen.dart';
import 'package:lockout/features/reader/presentation/reader_bookmarks_screen.dart';

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

  Future<void> pumpBookmarks(
    WidgetTester tester, {
    required FakeReaderRepository reader,
  }) async {
    useTallScreen(tester);
    final sources = FakeReaderSourceRepository(sources: const [source]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerRepositoryProvider.overrideWithValue(reader),
          readerSourceRepositoryProvider.overrideWithValue(sources),
          readerContentExtractionEnabledProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ReaderBookmarksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists bookmarks and removes one after unbookmarking', (
    tester,
  ) async {
    final reader = FakeReaderRepository();
    reader.articles['a'] = readerArticle(
      id: 'a',
      title: 'Article A',
      sourceName: 'Example Review',
      contentHtml: '<p>Words from A.</p>',
      isBookmarked: true,
    );
    reader.articles['b'] = readerArticle(
      id: 'b',
      title: 'Article B',
      sourceName: 'Example Review',
      isBookmarked: true,
    );
    reader.articles['c'] = readerArticle(
      id: 'c',
      title: 'Not saved',
      sourceName: 'Example Review',
    );

    await pumpBookmarks(tester, reader: reader);

    expect(find.text('Article A'), findsOneWidget);
    expect(find.text('Article B'), findsOneWidget);
    expect(find.text('Not saved'), findsNothing);

    await tester.tap(find.text('Article A'));
    await tester.pumpAndSettle();
    expect(find.byType(ReaderArticleScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Remove bookmark'));
    await tester.pumpAndSettle();
    expect(reader.articles['a']!.isBookmarked, isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Article A'), findsNothing);
    expect(find.text('Article B'), findsOneWidget);
    expect(reader.articles['b']!.isBookmarked, isTrue);
  });

  testWidgets('shows an empty state when nothing is saved', (tester) async {
    await pumpBookmarks(tester, reader: FakeReaderRepository());

    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(find.text('Back to today'), findsOneWidget);
  });
}
