import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/reader_source.dart';
import '../../domain/repositories/reader_source_repository.dart';
import '../local/app_database.dart';
import '../local/daos/reader_dao.dart';
import '../reader/reader_source_catalog.dart';

/// Drift-backed source store seeded from the bundled JSON catalogue.
class DriftReaderSourceRepository implements ReaderSourceRepository {
  DriftReaderSourceRepository(this._dao, this._catalogLoader);

  final ReaderDao _dao;
  final ReaderSourceCatalogLoader _catalogLoader;

  @override
  Future<void> synchronizeCatalog() async {
    final catalog = await _catalogLoader.load();
    for (final source in catalog.sources) {
      await _dao.upsertSourceDefinition(
        ReaderSourcesCompanion.insert(
          id: source.id,
          name: source.name,
          kind: source.kind.wireName,
          feedUrl: Value(source.feedUrl),
          siteUrl: source.siteUrl,
          enabled: Value(source.enabled),
          topicsJson: Value(jsonEncode(source.defaultTopics)),
          sortOrder: Value(source.sortOrder),
        ),
      );
    }
  }

  @override
  Future<List<ReaderSource>> loadSources() async {
    await synchronizeCatalog();
    final rows = await _dao.allSources();
    return List.unmodifiable(rows.map(_toDomain));
  }

  @override
  Future<List<ReaderSource>> enabledSources() async {
    final sources = await loadSources();
    return List.unmodifiable(
      sources.where((source) => source.enabled).toList(),
    );
  }

  @override
  Future<ReaderSource?> sourceById(String sourceId) async {
    final row = await _dao.sourceById(sourceId);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> setEnabled(String sourceId, bool enabled) {
    return _dao.setSourceEnabled(sourceId, enabled);
  }

  @override
  Future<void> setTopics(String sourceId, List<String> topics) {
    return _dao.setSourceTopics(sourceId, jsonEncode(topics));
  }

  @override
  Future<void> markFetched({
    required String sourceId,
    required DateTime at,
    String? etag,
    String? lastModified,
  }) {
    return _dao.markSourceFetched(
      id: sourceId,
      at: at,
      etag: etag,
      lastModified: lastModified,
    );
  }

  @override
  Future<void> markFetchFailed({
    required String sourceId,
    required String error,
  }) {
    return _dao.markSourceFailed(sourceId, error);
  }

  @override
  Future<DateTime?> lastRefreshAt() => _dao.lastRefreshAt();

  @override
  Future<ReaderSourceCatalog> catalog() => _catalogLoader.load();

  ReaderSource _toDomain(ReaderSourceRow row) {
    return ReaderSource(
      id: row.id,
      name: row.name,
      kind: ReaderSourceKind.fromWire(row.kind),
      feedUrl: row.feedUrl,
      siteUrl: row.siteUrl,
      enabled: row.enabled,
      topics: _decodeTopics(row.topicsJson),
      sortOrder: row.sortOrder,
      lastFetchedAt: row.lastFetchedAt,
      lastError: row.lastError,
      etag: row.etag,
      lastModified: row.lastModified,
    );
  }

  List<String> _decodeTopics(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return List.unmodifiable(decoded.whereType<String>());
      }
    } on FormatException {
      // A malformed preference must not make Reader unusable.
    }
    return const [];
  }
}
