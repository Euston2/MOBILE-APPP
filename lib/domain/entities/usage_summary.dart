import 'app_usage.dart';

/// Combined usage for one time window (in v1: since local midnight).
///
/// [perApp] is sorted by descending usage and only contains apps with a
/// positive total. [totalSeconds] is always the sum of [perApp].
class UsageSummary {
  const UsageSummary({
    required this.windowStart,
    required this.windowEnd,
    required this.totalSeconds,
    required this.perApp,
  });

  final DateTime windowStart;
  final DateTime windowEnd;
  final int totalSeconds;
  final List<AppUsage> perApp;

  bool get isEmpty => perApp.isEmpty;

  /// The app with the most usage, or null when nothing was used.
  AppUsage? get topApp => perApp.isEmpty ? null : perApp.first;

  Duration get total => Duration(seconds: totalSeconds);

  @override
  String toString() =>
      'UsageSummary(${windowStart.toIso8601String()}..'
      '${windowEnd.toIso8601String()}, ${totalSeconds}s, '
      '${perApp.length} apps)';
}
