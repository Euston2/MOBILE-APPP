import 'package:drift/drift.dart';

import '../../../core/utils/day_window.dart';
import '../../../domain/entities/reader_article.dart';
import '../app_database.dart';

part 'reader_dao.g.dart';

/// A cached article plus its bookmark state.
class ReaderArticleRecord {
  const ReaderArticleRecord({
    required this.article,
    required this.isBookmarked,
  });

  final ReaderArticleRow article;
  final bool isBookmarked;

  ReaderArticle toDomain() => ReaderArticle(
    id: article.id,
    sourceId: article.sourceId,
    sourceName: article.sourceName,
    title: article.title,
    url: article.url,
    excerpt: article.excerpt,
    contentHtml: article.contentHtml,
    readingMinutes: article.readingMinutes,
    publishedAt: article.publishedAt,
    fetchedAt: article.fetchedAt,
    isRead: article.isRead,
    isBookmarked: isBookmarked,
    pickDate: article.pickDate,
    pickRank: article.pickRank,
  );
}

@DriftAccessor(
  tables: [ReaderSources, ReaderArticles, ReaderBookmarks, ReadingSessions],
)
class ReaderDao extends DatabaseAccessor<AppDatabase> with _$ReaderDaoMixin {
  ReaderDao(super.db);

  // ---------------------------------------------------------------------------
  // Sources
  // ---------------------------------------------------------------------------

  Future<List<ReaderSourceRow>> allSources() {
    return (select(readerSources)..orderBy([
          (row) => OrderingTerm(expression: row.sortOrder),
          (row) => OrderingTerm(expression: row.name),
        ]))
        .get();
  }

  Future<ReaderSourceRow?> sourceById(String id) {
    return (select(
      readerSources,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertSourceDefinition(ReaderSourcesCompanion definition) async {
    final id = definition.id.value;
    final existing = await sourceById(id);
    if (existing == null) {
      await into(readerSources).insert(definition);
      return;
    }

    await (update(readerSources)..where((row) => row.id.equals(id))).write(
      ReaderSourcesCompanion(
        name: definition.name,
        kind: definition.kind,
        feedUrl: definition.feedUrl,
        siteUrl: definition.siteUrl,
        sortOrder: definition.sortOrder,
      ),
    );
  }

  Future<void> setSourceEnabled(String id, bool enabled) {
    return (update(readerSources)..where((row) => row.id.equals(id))).write(
      ReaderSourcesCompanion(enabled: Value(enabled)),
    );
  }

  Future<void> setSourceTopics(String id, String topicsJson) {
    return (update(readerSources)..where((row) => row.id.equals(id))).write(
      ReaderSourcesCompanion(topicsJson: Value(topicsJson)),
    );
  }

  Future<void> markSourceFetched({
    required String id,
    required DateTime at,
    String? etag,
    String? lastModified,
  }) {
    return (update(readerSources)..where((row) => row.id.equals(id))).write(
      ReaderSourcesCompanion(
        lastFetchedAt: Value(at),
        etag: Value(etag),
        lastModified: Value(lastModified),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> markSourceFailed(String id, String error) {
    return (update(readerSources)..where((row) => row.id.equals(id))).write(
      ReaderSourcesCompanion(lastError: Value(error)),
    );
  }

  Future<DateTime?> lastRefreshAt() async {
    final maxFetched = readerSources.lastFetchedAt.max();
    final row = await (selectOnly(
      readerSources,
    )..addColumns([maxFetched])).getSingle();
    return row.read(maxFetched);
  }

  // ---------------------------------------------------------------------------
  // Articles
  // ---------------------------------------------------------------------------

  Future<List<ReaderArticleRecord>> picksForDate(String date) async {
    final query = _articleRecords()
      ..where(readerArticles.pickDate.equals(date))
      ..orderBy([
        OrderingTerm(
          expression: readerArticles.pickRank,
          mode: OrderingMode.asc,
        ),
      ]);
    return _records(await query.get());
  }

  Future<List<ReaderArticleRecord>> unreadArticles({int limit = 200}) async {
    final query = _articleRecords()
      ..where(readerArticles.isRead.equals(false))
      ..orderBy([
        OrderingTerm(
          expression: readerArticles.publishedAt,
          mode: OrderingMode.desc,
        ),
        OrderingTerm(
          expression: readerArticles.fetchedAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);
    return _records(await query.get());
  }

  Future<ReaderArticleRecord?> articleById(String id) async {
    final query = _articleRecords()
      ..where(readerArticles.id.equals(id))
      ..limit(1);
    final rows = await query.get();
    if (rows.isEmpty) return null;
    return _record(rows.first);
  }

  Future<List<ReaderArticleRecord>> bookmarkedArticles() async {
    final query = _articleRecords(joinMode: _JoinMode.bookmarkedOnly)
      ..orderBy([
        OrderingTerm(
          expression: readerBookmarks.createdAt,
          mode: OrderingMode.desc,
        ),
      ]);
    return _records(await query.get());
  }

  Future<void> freezePicks(String date, List<String> articleIds) {
    return transaction(() async {
      for (var rank = 0; rank < articleIds.length; rank++) {
        await (update(
          readerArticles,
        )..where((row) => row.id.equals(articleIds[rank]))).write(
          ReaderArticlesCompanion(pickDate: Value(date), pickRank: Value(rank)),
        );
      }
    });
  }

  Future<void> saveFetched(List<ReaderArticle> articles) {
    return transaction(() async {
      for (final article in articles) {
        final existing = await (select(
          readerArticles,
        )..where((row) => row.id.equals(article.id))).getSingleOrNull();

        if (existing == null) {
          await into(readerArticles).insert(_companion(article));
          continue;
        }

        await (update(
          readerArticles,
        )..where((row) => row.id.equals(article.id))).write(
          ReaderArticlesCompanion(
            sourceId: Value(article.sourceId),
            sourceName: Value(article.sourceName),
            title: Value(article.title),
            url: Value(article.url),
            excerpt: article.excerpt.isEmpty
                ? const Value.absent()
                : Value(article.excerpt),
            contentHtml: article.contentHtml == null
                ? const Value.absent()
                : Value(article.contentHtml),
            readingMinutes: Value(
              article.readingMinutes > existing.readingMinutes
                  ? article.readingMinutes
                  : existing.readingMinutes,
            ),
            publishedAt: article.publishedAt == null
                ? const Value.absent()
                : Value(article.publishedAt),
            fetchedAt: Value(article.fetchedAt),
          ),
        );
      }
    });
  }

  Future<void> markRead(String id) {
    return (update(readerArticles)..where((row) => row.id.equals(id))).write(
      const ReaderArticlesCompanion(isRead: Value(true)),
    );
  }

  Future<void> setBookmarked(String articleId, bool bookmarked) async {
    if (bookmarked) {
      await into(readerBookmarks).insertOnConflictUpdate(
        ReaderBookmarksCompanion.insert(articleId: articleId),
      );
      return;
    }
    await (delete(
      readerBookmarks,
    )..where((row) => row.articleId.equals(articleId))).go();
  }

  Future<void> updateArticleContent({
    required String id,
    required String contentHtml,
    required int readingMinutes,
  }) {
    return (update(readerArticles)..where((row) => row.id.equals(id))).write(
      ReaderArticlesCompanion(
        contentHtml: Value(contentHtml),
        readingMinutes: Value(readingMinutes),
      ),
    );
  }

  Future<void> pruneBefore(DateTime cutoff) async {
    final bookmarked = selectOnly(readerBookmarks)
      ..addColumns([readerBookmarks.articleId]);
    await (delete(readerArticles)..where(
          (row) =>
              row.isRead.equals(false) &
              row.pickDate.isNull() &
              row.fetchedAt.isSmallerThanValue(cutoff) &
              row.id.isNotInQuery(bookmarked),
        ))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Reading sessions
  // ---------------------------------------------------------------------------

  Future<void> addReadingSeconds({
    required String date,
    required String articleId,
    required int seconds,
  }) {
    return customStatement(
      'INSERT INTO reading_sessions (date, article_id, seconds) '
      'VALUES (?, ?, ?) '
      'ON CONFLICT(date, article_id) DO UPDATE '
      'SET seconds = seconds + excluded.seconds',
      [date, articleId, seconds],
    );
  }

  Future<int> readingSecondsForDay(String date) async {
    final total = readingSessions.seconds.sum();
    final row =
        await (selectOnly(readingSessions)
              ..addColumns([total])
              ..where(readingSessions.date.equals(date)))
            .getSingle();
    return row.read(total) ?? 0;
  }

  Future<Map<String, int>> readingTotalsByDay({
    required DateTime start,
    required DateTime end,
  }) async {
    final startKey = localDateKey(start);
    final endKey = localDateKey(end);
    final total = readingSessions.seconds.sum();
    final query = selectOnly(readingSessions)
      ..addColumns([readingSessions.date, total])
      ..where(
        readingSessions.date.isBiggerOrEqualValue(startKey) &
            readingSessions.date.isSmallerThanValue(endKey),
      )
      ..groupBy([readingSessions.date]);

    final rows = await query.get();
    final totals = <String, int>{};
    for (final row in rows) {
      final date = row.read(readingSessions.date);
      if (date != null) totals[date] = row.read(total) ?? 0;
    }
    return totals;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  JoinedSelectStatement<HasResultSet, dynamic> _articleRecords({
    _JoinMode joinMode = _JoinMode.withBookmarkState,
  }) {
    final join = joinMode == _JoinMode.bookmarkedOnly
        ? innerJoin(
            readerBookmarks,
            readerBookmarks.articleId.equalsExp(readerArticles.id),
          )
        : leftOuterJoin(
            readerBookmarks,
            readerBookmarks.articleId.equalsExp(readerArticles.id),
          );
    return select(readerArticles).join([join]);
  }

  List<ReaderArticleRecord> _records(List<TypedResult> rows) {
    return [for (final row in rows) _record(row)];
  }

  ReaderArticleRecord _record(TypedResult row) {
    final article = row.readTable(readerArticles);
    final bookmark = row.readTableOrNull(readerBookmarks);
    return ReaderArticleRecord(
      article: article,
      isBookmarked: bookmark != null,
    );
  }

  ReaderArticlesCompanion _companion(ReaderArticle article) {
    return ReaderArticlesCompanion.insert(
      id: article.id,
      sourceId: article.sourceId,
      sourceName: article.sourceName,
      title: article.title,
      url: article.url,
      excerpt: Value(article.excerpt),
      contentHtml: Value(article.contentHtml),
      readingMinutes: Value(article.readingMinutes),
      publishedAt: Value(article.publishedAt),
      fetchedAt: article.fetchedAt,
    );
  }
}

enum _JoinMode { withBookmarkState, bookmarkedOnly }
