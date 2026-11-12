import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/di.dart';
import 'package:lockout/core/utils/day_window.dart';
import 'package:lockout/domain/entities/daily_archive.dart';
import 'package:lockout/features/history/presentation/history_controller.dart';

import '../helpers/fake_reader.dart';
import '../helpers/fake_stores.dart';

void main() {
  test('refresh imports a newly queued archive before reloading', () async {
    final history = FakeHistoryRepository();
    final container = ProviderContainer(
      overrides: [
        historyRepositoryProvider.overrideWithValue(history),
        readerRepositoryProvider.overrideWithValue(FakeReaderRepository()),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(historyControllerProvider.future);
    expect(initial.hasData, isFalse);

    final today = startOfLocalDay(DateTime.now());
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    history.pending = [
      DailyArchive(
        date: localDateKey(yesterday),
        totalSeconds: 1200,
        limitSeconds: 3600,
        apps: const {'com.example.app': 1200},
      ),
    ];

    await container.read(historyControllerProvider.notifier).refresh();

    final report = container.read(historyControllerProvider).value;
    expect(report, isNotNull);
    expect(report!.hasData, isTrue);
    expect(report.stats.totalSeconds, 1200);
    expect(report.days.last.date, yesterday);
    expect(history.saved, hasLength(1));
    expect(history.clearCalls, 1);
  });
}
