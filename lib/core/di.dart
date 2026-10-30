import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/blocking_repository.dart';
import '../domain/repositories/monitored_apps_repository.dart';
import '../domain/repositories/permissions_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/usage_repository.dart';

/// Composition root contracts.
///
/// The providers throw until `main.dart` (or a test) overrides them, which keeps
/// the presentation and domain layers free of any dependency on the Android
/// implementation.
final usageRepositoryProvider = Provider<UsageRepository>(
  (ref) => throw StateError(
    'usageRepositoryProvider must be overridden in the composition root.',
  ),
);

final permissionsRepositoryProvider = Provider<PermissionsRepository>(
  (ref) => throw StateError(
    'permissionsRepositoryProvider must be overridden in the composition root.',
  ),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw StateError(
    'settingsRepositoryProvider must be overridden in the composition root.',
  ),
);

final monitoredAppsRepositoryProvider = Provider<MonitoredAppsRepository>(
  (ref) => throw StateError(
    'monitoredAppsRepositoryProvider must be overridden in the composition root.',
  ),
);

final blockingRepositoryProvider = Provider<BlockingRepository>(
  (ref) => throw StateError(
    'blockingRepositoryProvider must be overridden in the composition root.',
  ),
);

/// How often the Home screen re-reads the usage counter.
///
/// The native `BlockingService` enforces the limit independently (every 2 s);
/// this timer only keeps the Flutter UI close to live. Tests stretch or disable
/// it.
final usagePollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 5),
);
