import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/di.dart';
import 'package:lockout/domain/entities/daily_archive.dart';
import 'package:lockout/features/history/presentation/archive_import_controller.dart';

import '../helpers/fake_stores.dart';

void main() {
  test('imports pending archives and clears the native queue', () async {
    final archives = [
      DailyArchive(
        date: '2026-10-29',
        totalSeconds: 3900,
        limitSeconds: 3600,
        limitHitAt: DateTime(2026, 10, 29, 14),
        apps: const {'com.instagram.android': 3900},
        focusSeconds: 1800,
        lateNightSeconds: 300,
        lateNightApps: const {'com.instagram.android': 300},
      ),
      DailyArchive(
        date: '2026-10-30',
        totalSeconds: 900,
        limitSeconds: 3600,
        apps: const {'com.zhiliaoapp.musically': 900},
        focusSeconds: 1200,
        lateNightSeconds: 120,
        lateNightApps: const {'com.zhiliaoapp.musically': 120},
      ),
    ];
    final history = FakeHistoryRepository(pending: archives);
    final container = ProviderContainer(
      overrides: [historyRepositoryProvider.overrideWithValue(history)],
    );
    addTearDown(container.dispose);

    final imported = await container.read(archiveImportProvider.future);

    expect(imported, 2);
    expect(history.saved, archives);
    expect(history.clearCalls, 1);
    expect(history.pending, isEmpty);
  });

  test('does not touch the queue when there is nothing to import', () async {
    final history = FakeHistoryRepository();
    final container = ProviderContainer(
      overrides: [historyRepositoryProvider.overrideWithValue(history)],
    );
    addTearDown(container.dispose);

    expect(await container.read(archiveImportProvider.future), 0);
    expect(history.saved, isEmpty);
    expect(history.clearCalls, 0);
  });
}
