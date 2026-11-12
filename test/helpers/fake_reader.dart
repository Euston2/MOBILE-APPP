import 'package:lockout/domain/entities/reader_article.dart';
import 'package:lockout/domain/entities/reader_feed.dart';
import 'package:lockout/domain/entities/reader_source.dart';
import 'package:lockout/domain/repositories/reader_repository.dart';
import 'package:lockout/domain/repositories/reader_source_repository.dart';

class FakeReaderRepository implements ReaderRepository {
  final Map<String, ReaderArticle> articles = {};
  final Map<String, List<String>> dailyPicks = {};
  final List<List<ReaderArticle>> savedBatches = [];
  final Map<String, Map<String, int>> readingSessions = {};
  String? frozenDate;
  List<String>? frozenIds;
  DateTime? prunedBefore;

  @override
  Future<List<ReaderArticle>> picksForDate(String date) async {
    final ids = dailyPicks[date] ?? const [];
    return [for (final id in ids) ?articles[id]];
  }

  @override
  Future<List<ReaderArticle>> unreadArticles({int limit = 200}) async {
    final values = articles.values.where((article) => !article.isRead).toList()
      ..sort((a, b) {
        final left = b.publishedAt ?? b.fetchedAt;
        final right = a.publishedAt ?? a.fetchedAt;
        return left.compareTo(right);
      });
    return values.take(limit).toList();
  }

  @override
  Future<void> freezePicks(String date, List<String> articleIds) async {
    frozenDate = date;
    frozenIds = List.of(articleIds);
    dailyPicks[date] = List.of(articleIds);
    for (var i = 0; i < articleIds.length; i++) {
      final article = articles[articleIds[i]];
      if (article == null) continue;
      articles[articleIds[i]] = article.copyWith(pickDate: date, pickRank: i);
    }
  }

  @override
  Future<ReaderArticle?> articleById(String id) async => articles[id];

  @override
  Future<void> saveFetched(List<ReaderArticle> incoming) async {
    savedBatches.add(List.of(incoming));
    for (final article in incoming) {
      final previous = articles[article.id];
      articles[article.id] = previous == null
          ? article
          : article.copyWith(
              isRead: previous.isRead,
              isBookmarked: previous.isBookmarked,
              pickDate: previous.pickDate,
              pickRank: previous.pickRank,
            );
    }
  }

  @override
  Future<void> markRead(String id) async {
    final article = articles[id];
    if (article != null) articles[id] = article.copyWith(isRead: true);
  }

  @override
  Future<void> setBookmarked(String id, bool bookmarked) async {
    final article = articles[id];
    if (article != null) {
      articles[id] = article.copyWith(isBookmarked: bookmarked);
    }
  }

  @override
  Future<List<ReaderArticle>> bookmarks() async {
    return articles.values.where((article) => article.isBookmarked).toList();
  }

  @override
  Future<void> updateArticleContent({
    required String id,
    required String contentHtml,
    required int readingMinutes,
  }) async {
    final article = articles[id];
    if (article != null) {
      articles[id] = article.copyWith(
        contentHtml: contentHtml,
        readingMinutes: readingMinutes,
      );
    }
  }

  @override
  Future<void> addReadingSeconds({
    required String date,
    required String articleId,
    required int seconds,
  }) async {
    final day = readingSessions.putIfAbsent(date, () => {});
    day[articleId] = (day[articleId] ?? 0) + seconds;
  }

  @override
  Future<int> readingSecondsForDay(String date) async {
    return readingSessions[date]?.values.fold<int>(0, (a, b) => a + b) ?? 0;
  }

  @override
  Future<Map<String, int>> readingTotalsByDay({
    required DateTime start,
    required DateTime end,
  }) async {
    return {
      for (final entry in readingSessions.entries)
        entry.key: entry.value.values.fold<int>(0, (a, b) => a + b),
    };
  }

  @override
  Future<void> pruneBefore(DateTime cutoff) async {
    prunedBefore = cutoff;
    articles.removeWhere(
      (_, article) =>
          !article.isRead &&
          !article.isBookmarked &&
          article.fetchedAt.isBefore(cutoff),
    );
  }
}

class FakeReaderSourceRepository implements ReaderSourceRepository {
  FakeReaderSourceRepository({
    List<ReaderSource> sources = const [],
    ReaderSourceCatalog catalog = const ReaderSourceCatalog(
      topics: [],
      sources: [],
    ),
  }) : _sources = List.of(sources),
       _catalog = catalog;

  final List<ReaderSource> _sources;
  final ReaderSourceCatalog _catalog;
  final Map<String, DateTime> fetchedAt = {};
  final Map<String, String> failures = {};
  int synchronizeCalls = 0;

  @override
  Future<List<ReaderSource>> loadSources() async => List.of(_sources);

  @override
  Future<List<ReaderSource>> enabledSources() async {
    return _sources.where((source) => source.enabled).toList();
  }

  @override
  Future<ReaderSource?> sourceById(String sourceId) async {
    for (final source in _sources) {
      if (source.id == sourceId) return source;
    }
    return null;
  }

  @override
  Future<void> setEnabled(String sourceId, bool enabled) async {
    final index = _sources.indexWhere((source) => source.id == sourceId);
    if (index >= 0) {
      _sources[index] = _sources[index].copyWith(enabled: enabled);
    }
  }

  @override
  Future<void> setTopics(String sourceId, List<String> topics) async {
    final index = _sources.indexWhere((source) => source.id == sourceId);
    if (index >= 0) _sources[index] = _sources[index].copyWith(topics: topics);
  }

  @override
  Future<void> markFetched({
    required String sourceId,
    required DateTime at,
    String? etag,
    String? lastModified,
  }) async {
    fetchedAt[sourceId] = at;
    failures.remove(sourceId);
  }

  @override
  Future<void> markFetchFailed({
    required String sourceId,
    required String error,
  }) async {
    failures[sourceId] = error;
  }

  @override
  Future<DateTime?> lastRefreshAt() async {
    if (fetchedAt.isEmpty) return null;
    return fetchedAt.values.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Future<void> synchronizeCatalog() async {
    synchronizeCalls++;
  }

  @override
  Future<ReaderSourceCatalog> catalog() async => _catalog;
}

class FakeReaderFeedClient implements ReaderFeedClient {
  FakeReaderFeedClient({
    required this.kind,
    this.result = const ReaderFeedResult(items: []),
    this.error,
  });

  @override
  final ReaderSourceKind kind;
  final ReaderFeedResult result;
  final Object? error;
  int calls = 0;

  @override
  Future<ReaderFeedResult> fetch(ReaderSource source) async {
    calls++;
    if (error case final error?) throw error;
    return result;
  }
}

ReaderArticle readerArticle({
  required String id,
  String sourceId = 'source',
  String sourceName = 'Source',
  String? title,
  String? url,
  String excerpt = 'Short excerpt',
  String? contentHtml,
  int readingMinutes = 1,
  DateTime? publishedAt,
  DateTime? fetchedAt,
  bool isRead = false,
  bool isBookmarked = false,
}) {
  return ReaderArticle(
    id: id,
    sourceId: sourceId,
    sourceName: sourceName,
    title: title ?? 'Article $id',
    url: url ?? 'https://example.com/$id',
    excerpt: excerpt,
    contentHtml: contentHtml,
    readingMinutes: readingMinutes,
    publishedAt: publishedAt,
    fetchedAt: fetchedAt ?? DateTime(2026, 11, 12),
    isRead: isRead,
    isBookmarked: isBookmarked,
  );
}
