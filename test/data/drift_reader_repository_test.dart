import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/data/local/app_database.dart';
import 'package:lockout/data/local/daos/reader_dao.dart';
import 'package:lockout/data/repositories/drift_reader_repository.dart';

import '../helpers/fake_reader.dart';

void main() {
  late AppDatabase database;
  late ReaderDao dao;
  late DriftReaderRepository repository;

  setUp(() {
    database = AppDatabase.memory();
    dao = ReaderDao(database);
    repository = DriftReaderRepository(dao);
  });

  tearDown(() => database.close());

  test(
    'stores articles, freezes daily picks and preserves user state',
    () async {
      final first = readerArticle(
        id: 'first',
        sourceId: 'source',
        title: 'First',
        url: 'https://example.com/first',
        publishedAt: DateTime(2026, 11, 12, 8),
      );
      final second = readerArticle(
        id: 'second',
        title: 'Second',
        url: 'https://example.com/second',
        publishedAt: DateTime(2026, 11, 12, 9),
      );

      await repository.saveFetched([first, second]);
      await repository.freezePicks('2026-11-12', ['first', 'second']);

      var picks = await repository.picksForDate('2026-11-12');
      expect(picks.map((article) => article.id), ['first', 'second']);
      expect(picks.every((article) => !article.isBookmarked), isTrue);

      await repository.markRead('first');
      await repository.setBookmarked('first', true);

      picks = await repository.picksForDate('2026-11-12');
      expect(picks.first.isRead, isTrue);
      expect(picks.first.isBookmarked, isTrue);
      expect(picks.first.pickRank, 0);
      expect((await repository.bookmarks()).single.id, 'first');
      expect((await repository.unreadArticles()).single.id, 'second');

      await repository.updateArticleContent(
        id: 'first',
        contentHtml: '<p>${List.filled(250, 'word').join(' ')}</p>',
        readingMinutes: 2,
      );

      await repository.saveFetched([
        first.copyWith(title: 'First updated', contentHtml: null),
      ]);
      final updated = await repository.articleById('first');
      expect(updated!.title, 'First updated');
      expect(updated.contentHtml, isNotNull);
      expect(updated.readingMinutes, 2);
      expect(updated.isRead, isTrue);
      expect(updated.isBookmarked, isTrue);
      expect(updated.pickDate, '2026-11-12');
    },
  );

  test('accumulates reading seconds per day and article', () async {
    await repository.addReadingSeconds(
      date: '2026-11-12',
      articleId: 'first',
      seconds: 30,
    );
    await repository.addReadingSeconds(
      date: '2026-11-12',
      articleId: 'first',
      seconds: 60,
    );
    await repository.addReadingSeconds(
      date: '2026-11-12',
      articleId: 'second',
      seconds: 20,
    );
    await repository.addReadingSeconds(
      date: '2026-11-13',
      articleId: 'third',
      seconds: 45,
    );

    expect(await repository.readingSecondsForDay('2026-11-12'), 110);
    expect(
      await repository.readingTotalsByDay(
        start: DateTime(2026, 11, 12),
        end: DateTime(2026, 11, 14),
      ),
      {'2026-11-12': 110, '2026-11-13': 45},
    );
  });

  test('prunes only old unread, unbookmarked cache entries', () async {
    final cutoff = DateTime(2026, 11, 1);
    final old = readerArticle(id: 'old', fetchedAt: DateTime(2026, 10, 1));
    final oldBookmarked = readerArticle(
      id: 'old-bookmarked',
      fetchedAt: DateTime(2026, 10, 1),
    );
    final oldRead = readerArticle(
      id: 'old-read',
      fetchedAt: DateTime(2026, 10, 1),
      isRead: true,
    );
    final recent = readerArticle(
      id: 'recent',
      fetchedAt: DateTime(2026, 11, 10),
    );
    await repository.saveFetched([old, oldBookmarked, oldRead, recent]);
    await repository.setBookmarked('old-bookmarked', true);
    await repository.markRead('old-read');

    await repository.pruneBefore(cutoff);

    expect(await repository.articleById('old'), isNull);
    expect(await repository.articleById('old-bookmarked'), isNotNull);
    expect(await repository.articleById('old-read'), isNotNull);
    expect(await repository.articleById('recent'), isNotNull);
  });
}
