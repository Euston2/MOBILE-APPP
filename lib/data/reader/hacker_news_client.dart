import 'package:dio/dio.dart';

import '../../domain/entities/reader_feed.dart';
import '../../domain/entities/reader_source.dart';
import '../../domain/usecases/reading_time.dart';
import 'reader_http.dart';

/// Fetches the current Hacker News front page through the official Firebase API.
class HackerNewsClient implements ReaderFeedClient {
  HackerNewsClient({Dio? dio, this.itemLimit = 30, this.batchSize = 6})
    : _dio = dio ?? buildReaderDio();

  final Dio _dio;
  final int itemLimit;
  final int batchSize;

  @override
  ReaderSourceKind get kind => ReaderSourceKind.hackerNews;

  @override
  Future<ReaderFeedResult> fetch(ReaderSource source) async {
    final topStoriesUrl =
        source.feedUrl ??
        'https://hacker-news.firebaseio.com/v0/topstories.json';
    final response = await _dio.get<List<dynamic>>(topStoriesUrl);
    final ids = (response.data ?? const [])
        .whereType<num>()
        .map((id) => id.toInt())
        .take(itemLimit)
        .toList();
    if (ids.isEmpty) return const ReaderFeedResult(items: []);

    final base = _apiBase(topStoriesUrl);
    final items = <ReaderFeedItem>[];

    for (var offset = 0; offset < ids.length; offset += batchSize) {
      final batch = ids.skip(offset).take(batchSize);
      final results = await Future.wait(
        batch.map((id) async {
          try {
            return await _fetchItem(base, id);
          } on Object {
            // A deleted or malformed item must not discard the whole page.
            return null;
          }
        }),
      );
      items.addAll(results.whereType<ReaderFeedItem>());
    }

    return ReaderFeedResult(items: List.unmodifiable(items));
  }

  Future<ReaderFeedItem?> _fetchItem(String base, int id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$base/item/$id.json',
    );
    final data = response.data;
    if (data == null) return null;
    if (data['type'] != 'story' ||
        data['deleted'] == true ||
        data['dead'] == true) {
      return null;
    }

    final title = (data['title'] as String?)?.trim() ?? '';
    final url = (data['url'] as String?)?.trim() ?? '';
    if (title.isEmpty || url.isEmpty) return null;

    final text = (data['text'] as String?)?.trim() ?? '';
    final score = (data['score'] as num?)?.toInt() ?? 0;
    final comments = (data['descendants'] as num?)?.toInt() ?? 0;
    final author = (data['by'] as String?)?.trim() ?? 'Hacker News';
    final published = (data['time'] as num?)?.toInt();

    return ReaderFeedItem(
      title: title,
      url: url,
      excerpt: text.isNotEmpty
          ? plainTextPreview(text)
          : '$author · $score points · $comments comments',
      contentHtml: estimateReadingMinutes(text) >= 2 ? text : null,
      publishedAt: published == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              published * 1000,
              isUtc: true,
            ).toLocal(),
    );
  }

  String _apiBase(String topStoriesUrl) {
    final index = topStoriesUrl.lastIndexOf('/');
    if (index <= 0) return 'https://hacker-news.firebaseio.com/v0';
    return topStoriesUrl.substring(0, index);
  }
}
