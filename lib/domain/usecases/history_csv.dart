import '../../core/utils/day_window.dart';
import '../entities/history_day.dart';

/// Builds a spreadsheet-friendly CSV snapshot of archived days.
///
/// Only days with usage are exported: those are the days Lockout actually
/// tracked. The per-app breakdown is kept in one column as
/// `package=seconds|package=seconds`, sorted by package, so the main row stays
/// one line per day. Fields containing a comma, quote or newline are quoted and
/// doubled per RFC 4180.
String historyCsv(Iterable<HistoryDay> days) {
  final rows = <String>['date,total_seconds,limit_seconds,limit_hit_at,apps'];

  final archived = days.where((day) => day.hasUsage).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  for (final day in archived) {
    final appEntries = day.apps.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final apps = appEntries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('|');

    rows.add(
      [
        localDateKey(day.date),
        day.totalSeconds.toString(),
        day.limitSeconds.toString(),
        day.limitHitAt?.toIso8601String() ?? '',
        apps,
      ].map(_csvField).join(','),
    );
  }

  // CRLF and a trailing newline open cleanly in Excel and Google Sheets.
  return '${rows.join('\r\n')}\r\n';
}

String _csvField(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
