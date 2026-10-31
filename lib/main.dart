import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di.dart';
import 'data/local/app_database.dart';
import 'data/repositories/android_blocking_repository.dart';
import 'data/repositories/android_permissions_repository.dart';
import 'data/repositories/android_usage_repository.dart';
import 'data/repositories/drift_history_repository.dart';
import 'data/repositories/drift_monitored_apps_repository.dart';
import 'data/repositories/prefs_settings_repository.dart';
import 'platform/lockout_platform.dart';

/// Composition root: the only place where platform implementations are bound
/// to the domain contracts.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final platform = LockoutPlatform();
  final preferences = await SharedPreferences.getInstance();
  final database = AppDatabase.open();

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
      ],
      child: const LockoutApp(),
    ),
  );
}
