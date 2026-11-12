import '../../domain/entities/reader_article.dart';
import '../../domain/repositories/reader_repository.dart';
import '../local/daos/reader_dao.dart';

/// Drift-backed article, bookmark and reading-session store.
class DriftReaderRepository implements ReaderRepository {
  DriftReaderRepository(this._dao);

  final ReaderDao _dao;

  @override
  Future<List<ReaderArticle>> picksForDate(String date) async {
    final rows = await _dao.picksForDate(date);
    return List.unmodifiable(rows.map((row) => row.toDomain()));
  }

  @override
  Future<List<ReaderArticle>> unreadArticles({int limit = 200}) async {
    final rows = await _dao.unreadArticles(limit: limit);
    return List.unmodifiable(rows.map((row) => row.toDomain()));
  }

  @override
  Future<void> freezePicks(String date, List<String> articleIds) {
    return _dao.freezePicks(date, articleIds);
  }

  @override
  Future<ReaderArticle?> articleById(String id) async {
    final row = await _dao.articleById(id);
    return row?.toDomain();
  }

  @override
  Future<void> saveFetched(List<ReaderArticle> articles) {
    return _dao.saveFetched(articles);
  }

  @override
  Future<void> markRead(String id) => _dao.markRead(id);

  @override
  Future<void> setBookmarked(String id, bool bookmarked) {
    return _dao.setBookmarked(id, bookmarked);
  }

  @override
  Future<List<ReaderArticle>> bookmarks() async {
    final rows = await _dao.bookmarkedArticles();
    return List.unmodifiable(rows.map((row) => row.toDomain()));
  }

  @override
  Future<void> updateArticleContent({
    required String id,
    required String contentHtml,
    required int readingMinutes,
  }) {
    return _dao.updateArticleContent(
      id: id,
      contentHtml: contentHtml,
      readingMinutes: readingMinutes,
    );
  }

  @override
  Future<void> addReadingSeconds({
    required String date,
    required String articleId,
    required int seconds,
  }) {
    return _dao.addReadingSeconds(
      date: date,
      articleId: articleId,
      seconds: seconds,
    );
  }

  @override
  Future<int> readingSecondsForDay(String date) {
    return _dao.readingSecondsForDay(date);
  }

  @override
  Future<Map<String, int>> readingTotalsByDay({
    required DateTime start,
    required DateTime end,
  }) {
    return _dao.readingTotalsByDay(start: start, end: end);
  }

  @override
  Future<void> pruneBefore(DateTime cutoff) => _dao.pruneBefore(cutoff);
}
