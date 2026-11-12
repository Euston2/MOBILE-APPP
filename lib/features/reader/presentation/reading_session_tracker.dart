import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/utils/day_window.dart';
import '../../../domain/repositories/reader_repository.dart';

/// Accumulates visible reading time and writes it to the per-day session table.
///
/// The tracker never runs while the article screen is covered by another route
/// or the app is in the background. It also flushes on pause and dispose, so a
/// short read still gets recorded.
class ReadingSessionTracker {
  ReadingSessionTracker({
    required ReaderRepository repository,
    required String articleId,
    DateTime Function()? now,
    this.flushInterval = const Duration(seconds: 15),
  }) : _repository = repository,
       _articleId = articleId,
       _now = now ?? DateTime.now;

  final ReaderRepository _repository;
  final String _articleId;
  final DateTime Function() _now;
  final Duration flushInterval;

  Timer? _timer;
  DateTime? _lastTick;
  bool _running = false;
  bool _disposed = false;

  bool get isRunning => _running;

  void start() {
    if (_running || _disposed) return;
    _running = true;
    _lastTick = _now();
    _timer = Timer.periodic(flushInterval, (_) => unawaited(flush()));
  }

  Future<void> pause() async {
    if (!_running) {
      // Paused time must never be counted by a later dispose. A start() during
      // the flush below flips `_running` back on, so only clear when still off.
      _lastTick = null;
      return;
    }
    _running = false;
    _timer?.cancel();
    _timer = null;
    await flush();
    if (!_running) _lastTick = null;
  }

  Future<void> flush() async {
    final last = _lastTick;
    if (last == null) return;

    final now = _now();
    _lastTick = now;
    await _persist(last, now);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _running = false;
    _timer?.cancel();
    _timer = null;

    final last = _lastTick;
    _lastTick = null;
    if (last != null) unawaited(_persist(last, _now()));
  }

  Future<void> _persist(DateTime start, DateTime end) async {
    if (!end.isAfter(start)) return;
    final totals = secondsByLocalDay(start, end);
    for (final entry in totals.entries) {
      if (entry.value <= 0) continue;
      try {
        await _repository.addReadingSeconds(
          date: entry.key,
          articleId: _articleId,
          seconds: entry.value,
        );
      } on Object catch (error, stackTrace) {
        debugPrint('Reading session save failed: $error\n$stackTrace');
        return;
      }
    }
  }
}
