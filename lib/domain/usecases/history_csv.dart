import '../../core/utils/day_window.dart';
import '../entities/history_day.dart';

/// Builds a spreadsheet-friendly CSV snapshot of archived days.
///
/// Only days with activity are exported: usage, focus time or late-night usage.
/// The per-app breakdowns are kept in one column each as
/// `package=seconds|package=seconds`, sorted by package, so the main row stays
/// one line per day. Fields containing a comma, quote or newline are quoted and
/// doubled per RFC 4180.
String historyCsv(Iterable<HistoryDay> days) {
  final rows = <String>[
    'date,total_seconds,limit_seconds,limit_hit_at,focus_seconds,'
        'late_night_seconds,apps,late_night_apps',
  ];

  final archived = days.where((day) => day.hasActivity).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  for (final day in archived) {
    rows.add(
      [
        localDateKey(day.date),
        day.totalSeconds.toString(),
        day.limitSeconds.toString(),
        day.limitHitAt?.toIso8601String() ?? '',
        day.focusSeconds.toString(),
        day.lateNightSeconds.toString(),
        _packApps(day.apps),
        _packApps(day.lateNightApps),
      ].map(_csvField).join(','),
    );
  }

  // CRLF and a trailing newline open cleanly in Excel and Google Sheets.
  return '${rows.join('\r\n')}\r\n';
}

String _packApps(Map<String, int> apps) {
  final entries = apps.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((entry) => '${entry.key}=${entry.value}').join('|');
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
