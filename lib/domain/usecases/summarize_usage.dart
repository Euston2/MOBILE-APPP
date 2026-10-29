import '../entities/app_usage.dart';
import '../entities/usage_summary.dart';

/// Pure "time used today" aggregation.
///
/// The native layer returns per-package durations; this function is the single
/// place where they become the number the user sees. Keeping it pure makes the
/// boundary rules (duplicates, zero/negative values, app filtering) testable
/// without a device.
///
/// - entries for the same package are summed (defensive: the platform should
///   already return one entry per package);
/// - empty packages and non-positive totals are dropped;
/// - when [monitoredPackages] is provided, only those packages are counted;
/// - the result is sorted by descending usage.
UsageSummary summarizeUsage({
  required DateTime windowStart,
  required DateTime windowEnd,
  required Iterable<AppUsage> entries,
  Set<String>? monitoredPackages,
}) {
  final totals = <String, int>{};
  for (final entry in entries) {
    if (entry.packageName.isEmpty || entry.seconds <= 0) continue;
    if (monitoredPackages != null &&
        !monitoredPackages.contains(entry.packageName)) {
      continue;
    }
    totals[entry.packageName] =
        (totals[entry.packageName] ?? 0) + entry.seconds;
  }

  final perApp =
      totals.entries
          .map((e) => AppUsage(packageName: e.key, seconds: e.value))
          .toList()
        ..sort((a, b) => b.seconds.compareTo(a.seconds));

  final totalSeconds = perApp.fold<int>(0, (sum, usage) => sum + usage.seconds);

  return UsageSummary(
    windowStart: windowStart,
    windowEnd: windowEnd,
    totalSeconds: totalSeconds,
    perApp: List.unmodifiable(perApp),
  );
}
