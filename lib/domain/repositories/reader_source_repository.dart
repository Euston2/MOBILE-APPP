import '../entities/reader_source.dart';

/// Persistence and catalogue port for Reader sources.
abstract interface class ReaderSourceRepository {
  /// Loads the user's source rows. Synchronises the bundled catalogue first.
  Future<List<ReaderSource>> loadSources();

  Future<List<ReaderSource>> enabledSources();

  Future<void> setEnabled(String sourceId, bool enabled);

  Future<void> setTopics(String sourceId, List<String> topics);

  Future<void> markFetched({
    required String sourceId,
    required DateTime at,
    String? etag,
    String? lastModified,
  });

  Future<void> markFetchFailed({
    required String sourceId,
    required String error,
  });

  /// The newest successful fetch across all sources, if any.
  Future<DateTime?> lastRefreshAt();

  /// Reloads `assets/reader/sources.json` and upserts definitions.
  ///
  /// Existing enabled/topic choices are preserved.
  Future<void> synchronizeCatalog();

  Future<ReaderSourceCatalog> catalog();
}
