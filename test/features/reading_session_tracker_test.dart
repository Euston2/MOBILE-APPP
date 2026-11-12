import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/features/reader/presentation/reading_session_tracker.dart';

import '../helpers/fake_reader.dart';

void main() {
  test('reading time is split across local midnight', () async {
    final repository = FakeReaderRepository();
    var now = DateTime(2026, 11, 12, 23, 59, 50);
    final tracker = ReadingSessionTracker(
      repository: repository,
      articleId: 'article',
      now: () => now,
      flushInterval: const Duration(hours: 1),
    );
    addTearDown(tracker.dispose);

    tracker.start();
    now = DateTime(2026, 11, 13, 0, 0, 10);
    await tracker.pause();

    expect(repository.readingSessions['2026-11-12'], {'article': 10});
    expect(repository.readingSessions['2026-11-13'], {'article': 10});
    expect(tracker.isRunning, isFalse);
  });

  test('repeated pauses and dispose do not count paused time', () async {
    final repository = FakeReaderRepository();
    var now = DateTime(2026, 11, 12, 9);
    final tracker = ReadingSessionTracker(
      repository: repository,
      articleId: 'article',
      now: () => now,
      flushInterval: const Duration(hours: 1),
    );
    addTearDown(tracker.dispose);

    tracker.start();
    now = DateTime(2026, 11, 12, 9, 0, 5);
    await tracker.pause();
    now = DateTime(2026, 11, 12, 10);
    await tracker.pause();
    tracker.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(repository.readingSessions['2026-11-12'], {'article': 5});
  });

  test('resuming starts a new bucket after the paused flush', () async {
    final repository = FakeReaderRepository();
    var now = DateTime(2026, 11, 12, 9);
    final tracker = ReadingSessionTracker(
      repository: repository,
      articleId: 'article',
      now: () => now,
      flushInterval: const Duration(hours: 1),
    );
    addTearDown(tracker.dispose);

    tracker.start();
    now = DateTime(2026, 11, 12, 9, 0, 5);
    await tracker.pause();
    now = DateTime(2026, 11, 12, 9, 0, 15);
    tracker.start();
    now = DateTime(2026, 11, 12, 9, 0, 20);
    await tracker.pause();

    expect(repository.readingSessions['2026-11-12'], {'article': 10});
  });
}
