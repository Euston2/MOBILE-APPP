import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';

/// Drains the native midnight archive into drift.
///
/// Watched by the app gate, so pending days are imported on launch, and
/// invalidated by Home's refresh to catch a reset that happened while the app
/// stayed open. Imports are idempotent (drift upserts by date); the native queue
/// is only cleared after every archive has been written.
final archiveImportProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(historyRepositoryProvider);
  final pending = await repository.readPendingArchives();
  if (pending.isEmpty) return 0;

  for (final archive in pending) {
    await repository.saveArchive(archive);
  }
  await repository.clearPendingArchives();
  return pending.length;
});
