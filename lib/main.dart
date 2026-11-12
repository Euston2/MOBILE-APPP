import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di.dart';
import 'core/reader_work.dart';
import 'data/local/app_database.dart';
import 'data/local/daos/reader_dao.dart';
import 'data/reader/devto_client.dart';
import 'data/reader/hacker_news_client.dart';
import 'data/reader/reader_source_catalog.dart';
import 'data/reader/rss_feed_client.dart';
import 'data/repositories/android_blocking_repository.dart';
import 'data/repositories/android_diagnostics_repository.dart';
import 'data/repositories/android_history_exporter.dart';
import 'data/repositories/android_permissions_repository.dart';
import 'data/repositories/android_usage_repository.dart';
import 'data/repositories/drift_history_repository.dart';
import 'data/repositories/drift_monitored_apps_repository.dart';
import 'data/repositories/drift_reader_repository.dart';
import 'data/repositories/drift_reader_source_repository.dart';
import 'data/repositories/prefs_settings_repository.dart';
import 'domain/entities/reader_source.dart';
import 'domain/usecases/refresh_reader.dart';
import 'platform/lockout_platform.dart';

/// Composition root: the only place where platform implementations are bound
/// to the domain contracts.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final platform = LockoutPlatform();
  final preferences = await SharedPreferences.getInstance();
  final database = AppDatabase.open();
  final readerDao = ReaderDao(database);
  final readerRepository = DriftReaderRepository(readerDao);
  final readerSourceRepository = DriftReaderSourceRepository(
    readerDao,
    const ReaderSourceCatalogLoader(),
  );
  final readerRefresh = RefreshReader(
    repository: readerRepository,
    sources: readerSourceRepository,
    clients: {
      ReaderSourceKind.rss: RssFeedClient(),
      ReaderSourceKind.hackerNews: HackerNewsClient(),
      ReaderSourceKind.devTo: DevToClient(),
    },
  );

  runApp(
    ProviderScope(
      overrides: [
        usageRepositoryProvider.overrideWithValue(
          AndroidUsageRepository(platform),
        ),
        permissionsRepositoryProvider.overrideWithValue(
          AndroidPermissionsRepository(platform),
        ),
        settingsRepositoryProvider.overrideWithValue(
          PrefsSettingsRepository(preferences),
        ),
        monitoredAppsRepositoryProvider.overrideWithValue(
          DriftMonitoredAppsRepository(database),
        ),
        blockingRepositoryProvider.overrideWithValue(
          AndroidBlockingRepository(platform),
        ),
        historyRepositoryProvider.overrideWithValue(
          DriftHistoryRepository(platform, database),
        ),
        diagnosticsRepositoryProvider.overrideWithValue(
          AndroidDiagnosticsRepository(platform),
        ),
        historyExporterProvider.overrideWithValue(
          AndroidHistoryExporter(platform),
        ),
        readerRepositoryProvider.overrideWithValue(readerRepository),
        readerSourceRepositoryProvider.overrideWithValue(
          readerSourceRepository,
        ),
        refreshReaderProvider.overrideWithValue(readerRefresh),
      ],
      child: const LockoutApp(),
    ),
  );

  if (Platform.isAndroid) {
    unawaited(_configureReaderRefreshSafely());
  }
}

Future<void> _configureReaderRefreshSafely() async {
  try {
    await configureReaderRefresh();
  } on Object catch (error, stackTrace) {
    // A WorkManager registration failure must not stop the app from opening.
    debugPrint('Could not schedule Reader refresh: $error\n$stackTrace');
  }
}
