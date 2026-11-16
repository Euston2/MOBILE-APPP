import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/utils/day_window.dart';

/// Reading seconds recorded for today's local date.
///
/// The Reader writes these rows from the article screen. The provider is
/// invalidated after each flush (and at midnight) so the native blocking config
/// can lift an unmet-reading block as soon as the goal is reached.
final readingSecondsTodayProvider = FutureProvider<int>((ref) async {
  final now = DateTime.now();
  final timer = Timer(
    nextLocalMidnight(now).difference(now) + const Duration(seconds: 1),
    ref.invalidateSelf,
  );
  ref.onDispose(timer.cancel);

  return ref
      .watch(readerRepositoryProvider)
      .readingSecondsForDay(localDateKey(now));
});
