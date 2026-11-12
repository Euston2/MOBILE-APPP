import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/local/app_database.dart';
import '../../data/local/daos/reader_dao.dart';
import '../../data/reader/devto_client.dart';
import '../../data/reader/hacker_news_client.dart';
import '../../data/reader/rss_feed_client.dart';
import '../../data/reader/reader_source_catalog.dart';
import '../../data/repositories/drift_reader_repository.dart';
import '../../data/repositories/drift_reader_source_repository.dart';
import '../../domain/entities/reader_source.dart';
import '../../domain/usecases/refresh_reader.dart';

const readerRefreshTaskName = 'reader-refresh';
const readerRefreshTaskUniqueName = 'lockout-reader-refresh';
const readerRefreshFrequency = Duration(hours: 6);

/// Entry point for WorkManager's background isolate.
///
/// A single periodic task is used. The task stores metadata and excerpts only;
/// full article extraction still happens when the user first opens an article.
@pragma('vm:entry-point')
void readerCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != readerRefreshTaskName) return true;

    DartPluginRegistrant.ensureInitialized();
    final database = AppDatabase.open();
    try {
      final dao = ReaderDao(database);
      final refresh = RefreshReader(
        repository: DriftReaderRepository(dao),
        sources: DriftReaderSourceRepository(
          dao,
          const ReaderSourceCatalogLoader(),
        ),
        clients: {
          ReaderSourceKind.rss: RssFeedClient(),
          ReaderSourceKind.hackerNews: HackerNewsClient(),
          ReaderSourceKind.devTo: DevToClient(),
        },
      );
      final result = await refresh();
      if (result.hasAnyFailure) {
        debugPrint(
          'Reader refresh completed with ${result.failures.length} '
          'source failure(s).',
        );
      }
      return true;
    } on Object catch (error, stackTrace) {
      debugPrint('Reader refresh failed: $error\n$stackTrace');
      return false;
    } finally {
      await database.close();
    }
  });
}

/// Registers the bounded background refresh.
///
/// WorkManager is the only component allowed to refresh without the user
/// opening Reader. The app itself opens cache-first.
Future<void> configureReaderRefresh() async {
  await Workmanager().initialize(readerCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    readerRefreshTaskUniqueName,
    readerRefreshTaskName,
    frequency: readerRefreshFrequency,
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}
