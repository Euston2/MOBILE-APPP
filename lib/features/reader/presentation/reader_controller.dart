import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/utils/day_window.dart';
import '../../../domain/entities/reader_article.dart';
import '../../../domain/entities/reader_feed.dart';

/// The shortest gap between two manual Reader refreshes.
///
/// WorkManager already updates the cache a few times a day. This cooldown stops
/// the refresh button from turning the Reader into a feed that is pulled on
/// every glance.
const readerManualRefreshCooldown = Duration(minutes: 15);

/// What happened when the reader refresh action ran.
enum ReaderRefreshKind { refreshed, busy, cooldown, failed }

class ReaderRefreshOutcome {
  const ReaderRefreshOutcome._(
    this.kind, {
    this.result,
    this.cooldownRemaining = Duration.zero,
  });

  const ReaderRefreshOutcome.refreshed(ReaderRefreshResult result)
    : this._(ReaderRefreshKind.refreshed, result: result);

  const ReaderRefreshOutcome.busy() : this._(ReaderRefreshKind.busy);

  const ReaderRefreshOutcome.cooldown(Duration remaining)
    : this._(ReaderRefreshKind.cooldown, cooldownRemaining: remaining);

  const ReaderRefreshOutcome.failed() : this._(ReaderRefreshKind.failed);

  final ReaderRefreshKind kind;
  final ReaderRefreshResult? result;
  final Duration cooldownRemaining;
}

/// Everything the Reader tab needs for one local day.
class ReaderDay {
  const ReaderDay({
    required this.date,
    required this.picks,
    required this.readingSeconds,
    required this.lastRefreshAt,
    this.failures = const [],
    this.isRefreshing = false,
    this.lastRefreshFailed = false,
  });

  /// Local `yyyy-MM-dd` key for the frozen list.
  final String date;
  final List<ReaderArticle> picks;
  final int readingSeconds;
  final DateTime? lastRefreshAt;
  final List<ReaderRefreshFailure> failures;
  final bool isRefreshing;
  final bool lastRefreshFailed;

  bool get isEmpty => picks.isEmpty;

  bool get isDone =>
      picks.isNotEmpty && picks.every((article) => article.isRead);

  bool get isOffline =>
      picks.isEmpty && (lastRefreshFailed || failures.isNotEmpty);

  bool get hasRefreshWarning => failures.isNotEmpty || lastRefreshFailed;

  int get unreadCount => picks.where((article) => !article.isRead).length;

  int get readCount => picks.length - unreadCount;

  int get totalMinutes =>
      picks.fold<int>(0, (total, article) => total + article.readingMinutes);

  ReaderDay copyWith({
    List<ReaderArticle>? picks,
    int? readingSeconds,
    DateTime? lastRefreshAt,
    List<ReaderRefreshFailure>? failures,
    bool? isRefreshing,
    bool? lastRefreshFailed,
  }) {
    return ReaderDay(
      date: date,
      picks: picks ?? this.picks,
      readingSeconds: readingSeconds ?? this.readingSeconds,
      lastRefreshAt: lastRefreshAt ?? this.lastRefreshAt,
      failures: failures ?? this.failures,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastRefreshFailed: lastRefreshFailed ?? this.lastRefreshFailed,
    );
  }
}

/// Loads the frozen daily list, cache-first.
///
/// A network refresh only happens automatically when there is no cache at all.
/// Otherwise the list stays put for the day and only WorkManager or an explicit
/// request updates it.
class ReaderController extends AsyncNotifier<ReaderDay> {
  bool _refreshing = false;
  Timer? _midnightTimer;
  DateTime? _lastManualAttemptAt;

  @override
  Future<ReaderDay> build() async {
    _midnightTimer?.cancel();
    ref.onDispose(() => _midnightTimer?.cancel());

    final now = DateTime.now();
    _scheduleMidnightRollover(now);
    final repository = ref.watch(readerRepositoryProvider);
    final sourceRepository = ref.watch(readerSourceRepositoryProvider);
    final curate = ref.watch(curateDailyReadingProvider);

    var picks = await curate(now);
    var failures = const <ReaderRefreshFailure>[];
    var refreshFailed = false;

    if (picks.isEmpty) {
      try {
        final result = await ref.read(refreshReaderProvider)();
        failures = result.failures;
      } on Object catch (error, stackTrace) {
        refreshFailed = true;
        debugPrint('Reader refresh failed: $error\n$stackTrace');
      }
      picks = await curate(now);
    }

    final date = localDateKey(now);
    final readingSeconds = await repository.readingSecondsForDay(date);
    final lastRefreshAt = await sourceRepository.lastRefreshAt();

    return ReaderDay(
      date: date,
      picks: picks,
      readingSeconds: readingSeconds,
      lastRefreshAt: lastRefreshAt,
      failures: failures,
      lastRefreshFailed: refreshFailed,
    );
  }

  /// Refreshes all sources, then rebuilds the list from the new cache.
  ///
  /// The cooldown is checked against both the last successful background fetch
  /// and the last manual attempt, so repeated taps cannot force a live feed.
  Future<ReaderRefreshOutcome> refresh() async {
    if (_refreshing) return const ReaderRefreshOutcome.busy();

    final now = DateTime.now();
    final latestUpdate = await _latestUpdateAt(state.value);
    final remaining = _cooldownRemaining(latestUpdate, now);
    if (remaining > Duration.zero) {
      return ReaderRefreshOutcome.cooldown(remaining);
    }

    _refreshing = true;
    _lastManualAttemptAt = now;
    final previous = state.value;
    if (previous != null) {
      state = AsyncData(
        previous.copyWith(isRefreshing: true, lastRefreshFailed: false),
      );
    }

    try {
      final result = await ref.read(refreshReaderProvider)();
      final date = localDateKey(now);
      final picks = await ref.read(curateDailyReadingProvider)(now);
      final readingSeconds = await ref
          .read(readerRepositoryProvider)
          .readingSecondsForDay(date);
      final lastRefreshAt = await ref
          .read(readerSourceRepositoryProvider)
          .lastRefreshAt();

      if (ref.mounted) {
        state = AsyncData(
          ReaderDay(
            date: date,
            picks: picks,
            readingSeconds: readingSeconds,
            lastRefreshAt: lastRefreshAt,
            failures: result.failures,
          ),
        );
      }
      return ReaderRefreshOutcome.refreshed(result);
    } on Object catch (error, stackTrace) {
      debugPrint('Reader refresh failed: $error\n$stackTrace');
      if (ref.mounted) {
        final fallback = state.value ?? previous;
        if (fallback != null) {
          state = AsyncData(
            fallback.copyWith(isRefreshing: false, lastRefreshFailed: true),
          );
        } else {
          state = AsyncError(error, stackTrace);
        }
      }
      return const ReaderRefreshOutcome.failed();
    } finally {
      _refreshing = false;
    }
  }

  /// Freezes a new list just after local midnight while the app stays open.
  void _scheduleMidnightRollover(DateTime now) {
    final next = nextLocalMidnight(now);
    _midnightTimer = Timer(
      next.difference(now) + const Duration(seconds: 1),
      () {
        if (ref.mounted) ref.invalidateSelf();
      },
    );
  }

  Future<DateTime?> _latestUpdateAt(ReaderDay? current) async {
    var latest = current?.lastRefreshAt;
    final stored = await ref
        .read(readerSourceRepositoryProvider)
        .lastRefreshAt();
    if (stored != null && (latest == null || stored.isAfter(latest))) {
      latest = stored;
    }
    if (_lastManualAttemptAt case final attempted?) {
      if (latest == null || attempted.isAfter(latest)) latest = attempted;
    }
    return latest;
  }

  Duration _cooldownRemaining(DateTime? latest, DateTime now) {
    if (latest == null) return Duration.zero;
    final elapsed = now.difference(latest);
    if (elapsed.isNegative) return readerManualRefreshCooldown;
    final remaining = readerManualRefreshCooldown - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

final readerControllerProvider =
    AsyncNotifierProvider<ReaderController, ReaderDay>(ReaderController.new);

/// Saved articles, ordered by the repository's most-recent-first query.
///
/// Auto-dispose keeps the list fresh after bookmarks are changed elsewhere
/// (for example from the daily Reader) and drops the small cache when closed.
final readerBookmarksProvider = FutureProvider.autoDispose<List<ReaderArticle>>(
  (ref) => ref.watch(readerRepositoryProvider).bookmarks(),
);
