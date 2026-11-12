import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/entities/reader_article.dart';
import 'package:lockout/domain/usecases/curate_daily_reading.dart';

import '../helpers/fake_reader.dart';

void main() {
  test('selects a source-balanced list capped at ten', () {
    final candidates = <ReaderArticle>[
      for (var i = 0; i < 6; i++)
        readerArticle(id: 'a$i', sourceId: 'alpha', sourceName: 'Alpha'),
      for (var i = 0; i < 5; i++)
        readerArticle(id: 'b$i', sourceId: 'beta', sourceName: 'Beta'),
      for (var i = 0; i < 2; i++)
        readerArticle(id: 'c$i', sourceId: 'gamma', sourceName: 'Gamma'),
    ];

    final picks = selectDailyPicks(candidates);

    expect(picks, hasLength(10));
    expect(picks.map((article) => article.id).toSet(), hasLength(10));
    expect(picks.take(3).map((article) => article.sourceId), [
      'alpha',
      'beta',
      'gamma',
    ]);
    expect(picks.where((article) => article.sourceId == 'gamma'), hasLength(2));
  });

  test('excludes already-read articles and is deterministic', () {
    final candidates = <ReaderArticle>[
      for (var i = 0; i < 12; i++)
        readerArticle(id: 'a$i', sourceName: 'Alpha', isRead: i == 0 || i == 5),
    ];

    final first = selectDailyPicks(candidates);
    final second = selectDailyPicks(candidates);

    expect(first, hasLength(10));
    expect(first.map((article) => article.id), isNot(contains('a0')));
    expect(first.map((article) => article.id), isNot(contains('a5')));
    expect(
      first.map((article) => article.id),
      second.map((article) => article.id),
    );
  });

  test('curation freezes an empty day only once', () async {
    final repository = FakeReaderRepository();
    for (var i = 0; i < 12; i++) {
      repository.articles['a$i'] = readerArticle(id: 'a$i');
    }
    final day = DateTime(2026, 11, 12);
    final usecase = CurateDailyReading(repository);

    final first = await usecase(day);
    final second = await usecase(day);

    expect(first, hasLength(10));
    expect(
      second.map((article) => article.id),
      first.map((article) => article.id),
    );
    expect(repository.frozenDate, '2026-11-12');
    expect(repository.frozenIds, hasLength(10));
  });

  test('existing picks are returned without refreezing', () async {
    final repository = FakeReaderRepository();
    repository.articles['existing'] = readerArticle(id: 'existing');
    repository.dailyPicks['2026-11-12'] = ['existing'];
    final usecase = CurateDailyReading(repository);

    final picks = await usecase(DateTime(2026, 11, 12));

    expect(picks.single.id, 'existing');
    expect(repository.frozenIds, isNull);
  });
}
