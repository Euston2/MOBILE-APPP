/// The kinds of remote sources the Reader can refresh.
enum ReaderSourceKind {
  rss,
  hackerNews,
  devTo;

  static ReaderSourceKind fromWire(String value) {
    return switch (value) {
      'rss' => ReaderSourceKind.rss,
      'hackerNews' => ReaderSourceKind.hackerNews,
      'devTo' => ReaderSourceKind.devTo,
      _ => throw FormatException('Unknown reader source kind: $value'),
    };
  }

  String get wireName => switch (this) {
    ReaderSourceKind.rss => 'rss',
    ReaderSourceKind.hackerNews => 'hackerNews',
    ReaderSourceKind.devTo => 'devTo',
  };
}

/// A source row as stored in drift.
class ReaderSource {
  const ReaderSource({
    required this.id,
    required this.name,
    required this.kind,
    required this.siteUrl,
    required this.enabled,
    required this.topics,
    required this.sortOrder,
    this.feedUrl,
    this.lastFetchedAt,
    this.lastError,
    this.etag,
    this.lastModified,
  });

  final String id;
  final String name;
  final ReaderSourceKind kind;
  final String? feedUrl;
  final String siteUrl;
  final bool enabled;

  /// Topic IDs chosen by the user. Some source kinds use these as query tags.
  final List<String> topics;
  final int sortOrder;
  final DateTime? lastFetchedAt;
  final String? lastError;
  final String? etag;
  final String? lastModified;

  ReaderSource copyWith({
    String? name,
    ReaderSourceKind? kind,
    String? feedUrl,
    String? siteUrl,
    bool? enabled,
    List<String>? topics,
    int? sortOrder,
    DateTime? lastFetchedAt,
    String? lastError,
    String? etag,
    String? lastModified,
    bool clearLastError = false,
  }) {
    return ReaderSource(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      feedUrl: feedUrl ?? this.feedUrl,
      siteUrl: siteUrl ?? this.siteUrl,
      enabled: enabled ?? this.enabled,
      topics: topics ?? this.topics,
      sortOrder: sortOrder ?? this.sortOrder,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      lastError: clearLastError ? null : lastError ?? this.lastError,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

/// A topic the Reader settings screen can expose.
class ReaderTopic {
  const ReaderTopic({required this.id, required this.label});

  final String id;
  final String label;
}

/// The editable source catalogue loaded from `assets/reader/sources.json`.
///
/// The catalogue is the default definition. Drift owns the user's enabled and
/// topic choices afterwards.
class ReaderSourceDefinition {
  const ReaderSourceDefinition({
    required this.id,
    required this.name,
    required this.kind,
    required this.siteUrl,
    required this.enabled,
    required this.defaultTopics,
    required this.availableTopics,
    required this.sortOrder,
    this.feedUrl,
  });

  final String id;
  final String name;
  final ReaderSourceKind kind;
  final String? feedUrl;
  final String siteUrl;
  final bool enabled;
  final List<String> defaultTopics;
  final List<String> availableTopics;
  final int sortOrder;
}

class ReaderSourceCatalog {
  const ReaderSourceCatalog({required this.topics, required this.sources});

  final List<ReaderTopic> topics;
  final List<ReaderSourceDefinition> sources;

  List<String> topicLabels(Iterable<String> ids) {
    final labels = <String, String>{
      for (final topic in topics) topic.id: topic.label,
    };
    return [for (final id in ids) ?labels[id]];
  }
}
