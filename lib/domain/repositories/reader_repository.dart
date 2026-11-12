import '../entities/reader_article.dart';

/// Persistence port for cached articles, bookmarks and reading sessions.
abstract interface class ReaderRepository {
  /// The frozen selection for [date]. [date] is a local `yyyy-MM-dd` key.
  Future<List<ReaderArticle>> picksForDate(String date);

  /// Unread cached articles, newest first. Used by daily curation.
  Future<List<ReaderArticle>> unreadArticles({int limit = 200});

  /// Stamps the daily list. Call only when [picksForDate] is empty.
  Future<void> freezePicks(String date, List<String> articleIds);

  Future<ReaderArticle?> articleById(String id);

  /// Inserts new articles and refreshes metadata on existing ones.
  ///
  /// Existing read/bookmark/pick state is preserved.
  Future<void> saveFetched(List<ReaderArticle> articles);

  Future<void> markRead(String id);

  Future<void> setBookmarked(String id, bool bookmarked);

  Future<List<ReaderArticle>> bookmarks();

  Future<void> updateArticleContent({
    required String id,
    required String contentHtml,
    required int readingMinutes,
  });

  /// Adds [seconds] to the `(date, articleId)` session row.
  Future<void> addReadingSeconds({
    required String date,
    required String articleId,
    required int seconds,
  });

  Future<int> readingSecondsForDay(String date);

  Future<Map<String, int>> readingTotalsByDay({
    required DateTime start,
    required DateTime end,
  });

  /// Drops old, unread, unbookmarked articles that are not a daily pick.
  Future<void> pruneBefore(DateTime cutoff);
}
