import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di.dart';
import 'data/repositories/android_permissions_repository.dart';
import 'data/repositories/android_usage_repository.dart';
import 'platform/lockout_platform.dart';

/// Composition root: the only place where platform implementations are bound
/// to the domain contracts.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final platform = LockoutPlatform();

  runApp(
    ProviderScope(
      overrides: [
        usageRepositoryProvider.overrideWithValue(
          AndroidUsageRepository(platform),
        ),
        permissionsRepositoryProvider.overrideWithValue(
          AndroidPermissionsRepository(platform),
        ),
      ],
      child: const LockoutApp(),
    ),
  );
}
