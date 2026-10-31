import '../../../domain/entities/history_day.dart';

/// Small, locale-independent labels used by the history screen.
///
/// Fixed English month/weekday names keep the chart axis width and the date
/// badges stable; times use 24-hour clock so a two-digit label always fits.

const _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String weekdayShort(DateTime date) => _weekdays[date.weekday - 1];

String shortDate(DateTime date) => '${_months[date.month - 1]} ${date.day}';

String longDate(DateTime date) => '${weekdayShort(date)}, ${shortDate(date)}';

String clockTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

/// "Oct 24 – Oct 30" for the padded window; empty when there are no days.
String rangeLabel(List<HistoryDay> days) {
  if (days.isEmpty) return '';
  final first = days.first.date;
  final last = days.last.date;
  if (first.year != last.year) {
    return '${shortDate(first)} ${first.year} – ${shortDate(last)} ${last.year}';
  }
  return '${shortDate(first)} – ${shortDate(last)}';
}
