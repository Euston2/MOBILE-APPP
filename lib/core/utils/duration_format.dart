/// Human-readable durations for the UI.
///
/// Deliberately coarse: "1h 05m" is what a person wants, not "3900 seconds".
String formatDuration(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  if (safe == 0) return '0m';
  if (safe < 60) return '<1m';

  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;

  if (hours == 0) return '${minutes}m';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}

/// Local clock label, e.g. "8:00 AM" or "12:30 PM".
String formatClockTime(DateTime moment) {
  final hour12 = moment.hour % 12 == 0 ? 12 : moment.hour % 12;
  final minute = moment.minute.toString().padLeft(2, '0');
  final suffix = moment.hour < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $suffix';
}

/// Countdown form used by the block screen: "3h 12m" or "45s".
String formatCountdown(Duration remaining) {
  if (remaining.isNegative || remaining == Duration.zero) return '0s';
  final hours = remaining.inHours;
  final minutes = remaining.inMinutes % 60;
  if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  if (minutes > 0) return '${minutes}m';
  return '${remaining.inSeconds}s';
}
