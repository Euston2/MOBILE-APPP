import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/reader_source.dart';

/// Loads the editable `assets/reader/sources.json` catalogue.
class ReaderSourceCatalogLoader {
  const ReaderSourceCatalogLoader({
    this.assetPath = 'assets/reader/sources.json',
  });

  final String assetPath;

  Future<ReaderSourceCatalog> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Reader source catalogue must be an object.');
    }
    return parse(decoded);
  }

  /// Kept public so the JSON shape can be tested without Flutter assets.
  ReaderSourceCatalog parse(Map<String, dynamic> json) {
    final topics = <ReaderTopic>[
      for (final item in _list(json['topics']))
        if (item is Map<String, dynamic>)
          ReaderTopic(
            id: _string(item['id'], fallback: ''),
            label: _string(item['label'], fallback: ''),
          ),
    ]..removeWhere((topic) => topic.id.isEmpty || topic.label.isEmpty);

    final topicIds = {for (final topic in topics) topic.id};
    final sources = <ReaderSourceDefinition>[];
    for (final item in _list(json['sources'])) {
      if (item is! Map<String, dynamic>) continue;
      final id = _string(item['id']);
      final name = _string(item['name']);
      final kindWire = _string(item['kind']);
      final siteUrl = _string(item['siteUrl']);
      if (id.isEmpty || name.isEmpty || kindWire.isEmpty || siteUrl.isEmpty) {
        continue;
      }

      final ReaderSourceKind kind;
      try {
        kind = ReaderSourceKind.fromWire(kindWire);
      } on FormatException {
        continue;
      }

      final defaultTopics = _topics(item['defaultTopics'], topicIds);
      final availableTopics = _topics(item['availableTopics'], topicIds);
      sources.add(
        ReaderSourceDefinition(
          id: id,
          name: name,
          kind: kind,
          feedUrl: _optionalString(item['feedUrl']),
          siteUrl: siteUrl,
          enabled: item['enabled'] != false,
          defaultTopics: defaultTopics,
          availableTopics: availableTopics,
          sortOrder: item['sortOrder'] is num
              ? (item['sortOrder'] as num).toInt()
              : sources.length,
        ),
      );
    }

    sources.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ReaderSourceCatalog(
      topics: List.unmodifiable(topics),
      sources: List.unmodifiable(sources),
    );
  }

  List<String> _topics(Object? raw, Set<String> known) {
    return [
      for (final item in _list(raw))
        if (item is String && known.contains(item)) item,
    ];
  }

  List<Object?> _list(Object? raw) => raw is List ? raw : const [];

  String _string(Object? raw, {String fallback = ''}) {
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return fallback;
  }

  String? _optionalString(Object? raw) {
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }
}
