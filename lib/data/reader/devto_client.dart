import 'package:dio/dio.dart';

import '../../domain/entities/reader_feed.dart';
import '../../domain/entities/reader_source.dart';
import '../../domain/usecases/reading_time.dart';
import 'reader_http.dart';

/// Fetches articles for the topics selected in Reader settings.
///
/// dev.to's tag API is used for topic filtering. If a source has no selected
/// topics, the general top list is fetched instead of returning an empty feed.
class DevToClient implements ReaderFeedClient {
  DevToClient({Dio? dio, this.perTopicLimit = 10, this.totalLimit = 30})
    : _dio = dio ?? buildReaderDio();

  final Dio _dio;
  final int perTopicLimit;
  final int totalLimit;

  @override
  ReaderSourceKind get kind => ReaderSourceKind.devTo;

  @override
  Future<ReaderFeedResult> fetch(ReaderSource source) async {
    final endpoint = source.feedUrl ?? 'https://dev.to/api/articles';
    final topics = source.topics.where((topic) => topic.trim().isNotEmpty);
    final queries = topics.isEmpty
        ? <Map<String, Object?>>[
            {'top': 7, 'per_page': perTopicLimit},
          ]
        : [
            for (final topic in topics)
              {'tag': topic, 'top': 7, 'per_page': perTopicLimit},
          ];

    final items = <ReaderFeedItem>[];
    final seen = <String>{};
    Object? lastError;
    var succeeded = false;

    for (final query in queries) {
      try {
        final response = await _dio.get<List<dynamic>>(
          endpoint,
          queryParameters: query,
        );
        succeeded = true;
        for (final raw in response.data ?? const []) {
          if (raw is! Map<String, dynamic>) continue;
          final item = _parse(raw);
          if (item != null && seen.add(item.url)) items.add(item);
          if (items.length >= totalLimit) break;
        }
      } on Object catch (error) {
        lastError = error;
      }
      if (items.length >= totalLimit) break;
    }

    if (!succeeded && lastError != null) {
      throw lastError;
    }
    return ReaderFeedResult(items: List.unmodifiable(items));
  }

  ReaderFeedItem? _parse(Map<String, dynamic> raw) {
    final title = (raw['title'] as String?)?.trim() ?? '';
    final url = (raw['url'] as String?)?.trim() ?? '';
    if (title.isEmpty || url.isEmpty) return null;

    final description = (raw['description'] as String?)?.trim() ?? '';
    final publishedAt = DateTime.tryParse(
      (raw['published_at'] as String?)?.trim() ?? '',
    );

    return ReaderFeedItem(
      title: title,
      url: url,
      excerpt: description.isEmpty
          ? 'Article on dev.to'
          : plainTextPreview(description),
      publishedAt: publishedAt,
    );
  }
}
