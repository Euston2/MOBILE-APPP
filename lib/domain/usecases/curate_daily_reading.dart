import '../../core/utils/day_window.dart';
import '../entities/reader_article.dart';
import '../repositories/reader_repository.dart';

/// Chooses a stable, source-balanced set of articles for one day.
///
/// This is intentionally not a recommendation algorithm: no personalisation,
/// no infinite pagination and no read history beyond excluding articles that
/// were already opened.
List<ReaderArticle> selectDailyPicks(
  Iterable<ReaderArticle> candidates, {
  int limit = 10,
}) {
  if (limit <= 0) return const [];

  final bySource = <String, List<ReaderArticle>>{};
  for (final article in candidates) {
    if (article.isRead) continue;
    (bySource[article.sourceId] ??= []).add(article);
  }
  for (final articles in bySource.values) {
    articles.sort(_newestFirst);
  }

  final sourceOrder = bySource.keys.toList()
    ..sort((a, b) {
      final left = bySource[a]!.first;
      final right = bySource[b]!.first;
      final byName = left.sourceName.compareTo(right.sourceName);
      return byName != 0 ? byName : a.compareTo(b);
    });

  final selected = <ReaderArticle>[];
  var round = 0;
  while (selected.length < limit) {
    var added = false;
    for (final sourceId in sourceOrder) {
      final articles = bySource[sourceId]!;
      if (round >= articles.length) continue;
      selected.add(articles[round]);
      added = true;
      if (selected.length == limit) break;
    }
    if (!added) break;
    round++;
  }

  if (selected.length < limit) {
    final chosen = selected.map((article) => article.id).toSet();
    final remaining =
        candidates
            .where((article) => !article.isRead && !chosen.contains(article.id))
            .toList()
          ..sort(_newestFirst);
    for (final article in remaining) {
      selected.add(article);
      if (selected.length == limit) break;
    }
  }

  return List.unmodifiable(selected);
}

int _newestFirst(ReaderArticle a, ReaderArticle b) {
  final published = (b.publishedAt ?? b.fetchedAt).compareTo(
    a.publishedAt ?? a.fetchedAt,
  );
  if (published != 0) return published;
  final fetched = b.fetchedAt.compareTo(a.fetchedAt);
  if (fetched != 0) return fetched;
  return a.id.compareTo(b.id);
}

/// Ensures today's list exists, but never extends a list that already has picks.
class CurateDailyReading {
  const CurateDailyReading(this.repository, {this.limit = 10});

  final ReaderRepository repository;
  final int limit;

  Future<List<ReaderArticle>> call(DateTime day) async {
    final date = localDateKey(day);
    final existing = await repository.picksForDate(date);
    if (existing.isNotEmpty) return existing;

    final candidates = await repository.unreadArticles();
    final picks = selectDailyPicks(candidates, limit: limit);
    if (picks.isNotEmpty) {
      await repository.freezePicks(date, [for (final pick in picks) pick.id]);
    }
    return picks;
  }
}
