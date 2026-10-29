import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/permissions_repository.dart';
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

/// How often the Home screen re-reads the usage counter.
///
/// Stage 3 moves the authoritative polling into the foreground service; this
/// provider lets tests shorten or disable the timer.
final usagePollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 5),
);
