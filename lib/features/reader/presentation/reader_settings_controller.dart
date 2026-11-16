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

  /// Topics offered by the sources the user has turned on.
  ///
  /// A topic can only do useful work when an enabled source supports it, so the
  /// global chip row deliberately follows the enabled set. Turning on another
  /// source adds its topics without changing the existing selection.
  List<ReaderTopic> get selectableTopics {
    final ids = <String>{};
    for (final source in sources.where((source) => source.enabled)) {
      ids.addAll(availableTopicsFor(source));
    }
    return [
      for (final topic in catalog.topics)
        if (ids.contains(topic.id)) topic,
    ];
  }

  bool isTopicSelected(String topicId) => sources.any(
    (source) => source.enabled && source.topics.contains(topicId),
  );

  int get selectedTopicCount =>
      selectableTopics.where((topic) => isTopicSelected(topic.id)).length;

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

  /// Applies one topic choice to every enabled source that supports it.
  ///
  /// This is the shortcut behind the "Topics you care about" chips. The
  /// per-source chips remain available for fine tuning; both paths write the
  /// same drift rows.
  Future<void> setTopicSelected(String topicId, bool selected) async {
    final previous = state.value;
    if (previous == null) return;

    final updates = <String, List<String>>{};
    for (final source in previous.sources) {
      if (!source.enabled) continue;
      if (!previous.availableTopicsFor(source).contains(topicId)) continue;

      final topics = List<String>.of(source.topics);
      if (selected) {
        if (topics.contains(topicId)) continue;
        topics.add(topicId);
      } else {
        if (!topics.remove(topicId)) continue;
      }
      updates[source.id] = topics;
    }
    await _applyTopicUpdates(previous, updates);
  }

  /// Clears every topic filter on the enabled sources.
  Future<void> clearTopics() async {
    final previous = state.value;
    if (previous == null) return;

    final updates = <String, List<String>>{
      for (final source in previous.sources)
        if (source.enabled && source.topics.isNotEmpty) source.id: const [],
    };
    await _applyTopicUpdates(previous, updates);
  }

  Future<void> _applyTopicUpdates(
    ReaderSourceSettings previous,
    Map<String, List<String>> updates,
  ) async {
    if (updates.isEmpty) return;

    final nextSources = [
      for (final source in previous.sources)
        if (updates[source.id] case final topics?)
          source.copyWith(topics: topics)
        else
          source,
    ];
    state = AsyncData(previous.copyWith(sources: nextSources));

    try {
      await Future.wait([
        for (final update in updates.entries)
          ref
              .read(readerSourceRepositoryProvider)
              .setTopics(update.key, update.value),
      ]);
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
