import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/utils/day_window.dart';
import '../../../domain/usecases/history_report.dart';
import 'archive_import_controller.dart';

/// Selected history window, in days: one week or one month.
class HistoryRangeController extends Notifier<int> {
  static const options = <int>[7, 30];

  @override
  int build() => options.first;

  void select(int days) {
    if (!options.contains(days) || days == state) return;
    state = days;
  }
}

final historyRangeProvider = NotifierProvider<HistoryRangeController, int>(
  HistoryRangeController.new,
);

/// Archived history for the selected window, ending yesterday.
///
/// The native midnight reset writes completed days to a queue; this controller
/// drains that queue first so a day archived while the app was closed appears
/// without needing a restart. Querying and padding happen in the domain so the
/// widgets only render a ready [HistoryReport].
class HistoryController extends AsyncNotifier<HistoryReport> {
  @override
  Future<HistoryReport> build() async {
    final range = ref.watch(historyRangeProvider);

    // `read` rather than `watch`: the import is a one-shot prerequisite, and
    // watching it here would rebuild the report a second time when it finishes.
    await ref.read(archiveImportProvider.future);
    return _load(range);
  }

  Future<HistoryReport> _load(int range) async {
    // History contains finished days only: today's live usage belongs to Home.
    final end = startOfLocalDay(DateTime.now());
    final start = DateTime(end.year, end.month, end.day - range);
    final stored = await ref
        .read(historyRepositoryProvider)
        .loadDays(start: start, end: end);

    // Reader time lives in its own table. A failure there must not hide the
    // social history, so treat it as zero reading and keep going.
    var readingByDay = const <String, int>{};
    try {
      readingByDay = await ref
          .read(readerRepositoryProvider)
          .readingTotalsByDay(start: start, end: end);
    } on Object catch (error, stackTrace) {
      debugPrint('Reading totals failed: $error\n$stackTrace');
    }

    return buildHistoryReport(
      stored: stored,
      endExclusive: end,
      dayCount: range,
      readingSecondsByDay: readingByDay,
    );
  }

  /// Re-imports pending archives, then reloads the current window.
  Future<void> refresh() async {
    final next = await AsyncValue.guard(() async {
      ref.invalidate(archiveImportProvider);
      await ref.read(archiveImportProvider.future);
      return _load(ref.read(historyRangeProvider));
    });
    if (ref.mounted) state = next;
  }
}

final historyControllerProvider =
    AsyncNotifierProvider<HistoryController, HistoryReport>(
      HistoryController.new,
    );
