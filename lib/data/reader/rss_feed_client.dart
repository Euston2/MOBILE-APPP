import 'dart:io';

import 'package:dart_rss/dart_rss.dart';
import 'package:dart_rss/domain/rss1_item.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/reader_feed.dart';
import '../../domain/entities/reader_source.dart';
import '../../domain/usecases/reading_time.dart';
import 'reader_http.dart';

/// Fetches RSS 1.0, RSS 2.0 and Atom feeds.
class RssFeedClient implements ReaderFeedClient {
  RssFeedClient({Dio? dio}) : _dio = dio ?? buildReaderDio();

  final Dio _dio;
  final RssFeedParser parser = const RssFeedParser();

  @override
  ReaderSourceKind get kind => ReaderSourceKind.rss;

  @override
  Future<ReaderFeedResult> fetch(ReaderSource source) async {
    final feedUrl = source.feedUrl;
    if (feedUrl == null || feedUrl.trim().isEmpty) {
      throw const FormatException('RSS source has no feed URL.');
    }

    final headers = <String, String>{};
    if (source.etag case final etag?) headers['If-None-Match'] = etag;
    if (source.lastModified case final modified?) {
      headers['If-Modified-Since'] = modified;
    }

    final response = await _dio.get<String>(
      feedUrl,
      options: Options(
        responseType: ResponseType.plain,
        headers: headers,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    if (response.statusCode == 304) {
      return ReaderFeedResult(
        items: const [],
        etag: source.etag,
        lastModified: source.lastModified,
      );
    }

    final body = response.data;
    if (body == null || body.trim().isEmpty) {
      throw const FormatException('The feed returned an empty response.');
    }

    return parser.parse(
      body,
      etag: response.headers.value('etag'),
      lastModified: response.headers.value('last-modified'),
    );
  }
}

/// Pure XML parser, kept separate so feeds can be tested without networking.
class RssFeedParser {
  const RssFeedParser();

  ReaderFeedResult parse(
    String xml, {
    String? etag,
    String? lastModified,
    int limit = 30,
  }) {
    final version = WebFeed.detectRssVersion(xml);
    final items = switch (version) {
      RssVersion.rss1 => _fromRss1(Rss1Feed.parse(xml).items),
      RssVersion.rss2 => _fromRss2(RssFeed.parse(xml).items),
      RssVersion.atom => _fromAtom(AtomFeed.parse(xml).items),
      RssVersion.unknown => throw const FormatException(
        'The response is not a recognised RSS or Atom feed.',
      ),
    };

    return ReaderFeedResult(
      items: List.unmodifiable(items.take(limit)),
      etag: etag,
      lastModified: lastModified,
    );
  }

  Iterable<ReaderFeedItem> _fromRss2(Iterable<RssItem> items) sync* {
    for (final item in items) {
      final link = item.link ?? item.guid;
      if (link == null) continue;
      final description = item.description ?? '';
      final encoded = item.content?.value;
      final content = _fullContent(encoded, description);
      yield ReaderFeedItem(
        title: item.title ?? '',
        url: link,
        excerpt: plainTextPreview(
          description.isNotEmpty ? description : content,
        ),
        contentHtml: content,
        publishedAt: _parseDate(item.pubDate),
      );
    }
  }

  Iterable<ReaderFeedItem> _fromRss1(Iterable<Rss1Item> items) sync* {
    for (final item in items) {
      if (item.link == null) continue;
      final description = item.description ?? item.dc?.description ?? '';
      final encoded = item.content?.value;
      final content = _fullContent(encoded, description);
      yield ReaderFeedItem(
        title: item.title ?? item.dc?.title ?? '',
        url: item.link!,
        excerpt: plainTextPreview(
          description.isNotEmpty ? description : content,
        ),
        contentHtml: content,
        publishedAt: _parseDate(item.dc?.date),
      );
    }
  }

  Iterable<ReaderFeedItem> _fromAtom(Iterable<AtomItem> items) sync* {
    for (final item in items) {
      final link = _atomHref(item);
      if (link == null) continue;

      final summary = item.summary ?? '';
      final content = _fullContent(item.content, summary);
      yield ReaderFeedItem(
        title: item.title ?? '',
        url: link,
        excerpt: plainTextPreview(summary.isNotEmpty ? summary : content),
        contentHtml: content,
        publishedAt: _parseDate(item.published ?? item.updated),
      );
    }
  }

  String? _atomHref(AtomItem item) {
    final links = item.links.where((link) => link.href != null).toList();
    if (links.isEmpty) return null;
    for (final link in links) {
      if (link.rel == null || link.rel == 'alternate') return link.href;
    }
    return links.first.href;
  }

  /// Only treat a body as cached full content when it is long enough to be more
  /// than a teaser. Otherwise the article screen runs Readability instead.
  String? _fullContent(String? primary, String fallback) {
    final value = (primary ?? '').trim();
    if (value.isNotEmpty && estimateReadingMinutes(value) >= 2) return value;
    if (estimateReadingMinutes(fallback) >= 2) return fallback;
    return null;
  }

  DateTime? _parseDate(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    try {
      return HttpDate.parse(value);
    } on Object {
      return null;
    }
  }
}
