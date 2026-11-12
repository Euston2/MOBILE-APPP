import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../domain/entities/reader_source.dart';

/// The bundled catalogue joined with the user's persisted source choices.
class ReaderSourceSettings {
  const ReaderSourceSettings({
    required this.catalog,
    required this.sources,
    required this.lastRefreshAt,
  });

  final ReaderSourceCatalog catalog;
  final List<ReaderSource> sources;
  final DateTime? lastRefreshAt;

  ReaderSourceDefinition? definitionFor(String sourceId) {
    for (final definition in catalog.sources) {
      if (definition.id == sourceId) return definition;
    }
    return null;
  }

  List<String> availableTopicsFor(ReaderSource source) {
    final definition = definitionFor(source.id);
    return definition?.availableTopics ?? const [];
  }

  String? topicLabel(String topicId) {
    for (final topic in catalog.topics) {
      if (topic.id == topicId) return topic.label;
    }
    return null;
  }

  int get enabledCount => sources.where((source) => source.enabled).length;

  ReaderSourceSettings copyWith({List<ReaderSource>? sources}) {
    return ReaderSourceSettings(
      catalog: catalog,
      sources: sources ?? this.sources,
      lastRefreshAt: lastRefreshAt,
    );
  }
}

/// Loads and saves the enabled sources and their topic filters.
///
/// Changes are applied optimistically because the store is local; a failed
/// write restores the previous rows and lets the screen report the error.
class ReaderSettingsController extends AsyncNotifier<ReaderSourceSettings> {
  @override
  Future<ReaderSourceSettings> build() async {
    final repository = ref.watch(readerSourceRepositoryProvider);
    final catalog = await repository.catalog();
    final sources = await repository.loadSources();
    final lastRefreshAt = await repository.lastRefreshAt();

    return ReaderSourceSettings(
      catalog: catalog,
      sources: sources,
      lastRefreshAt: lastRefreshAt,
    );
  }

  Future<void> setEnabled(String sourceId, bool enabled) async {
    final previous = state.value;
    if (previous == null) return;

    final index = previous.sources.indexWhere(
      (source) => source.id == sourceId,
    );
    if (index < 0) return;
    if (previous.sources[index].enabled == enabled) return;

    final nextSources = List<ReaderSource>.of(previous.sources);
    nextSources[index] = nextSources[index].copyWith(enabled: enabled);
    state = AsyncData(previous.copyWith(sources: nextSources));

    try {
      await ref
          .read(readerSourceRepositoryProvider)
          .setEnabled(sourceId, enabled);
    } on Object {
      if (ref.mounted) state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> toggleTopic(String sourceId, String topicId) async {
    final previous = state.value;
    if (previous == null) return;

    final index = previous.sources.indexWhere(
      (source) => source.id == sourceId,
    );
    if (index < 0) return;

    final source = previous.sources[index];
    final topics = List<String>.of(source.topics);
    if (topics.contains(topicId)) {
      topics.remove(topicId);
    } else {
      topics.add(topicId);
    }

    final nextSources = List<ReaderSource>.of(previous.sources);
    nextSources[index] = source.copyWith(topics: topics);
    state = AsyncData(previous.copyWith(sources: nextSources));

    try {
      await ref
          .read(readerSourceRepositoryProvider)
          .setTopics(sourceId, topics);
    } on Object {
      if (ref.mounted) state = AsyncData(previous);
      rethrow;
    }
  }
}

final readerSettingsControllerProvider =
    AsyncNotifierProvider<ReaderSettingsController, ReaderSourceSettings>(
      ReaderSettingsController.new,
    );
