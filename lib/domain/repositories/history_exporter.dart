/// Outbound port for sending a generated history snapshot to another app.
///
/// Kept as a domain contract so the history screen can be widget-tested without
/// the Android share sheet. The Android implementation uses the system
/// `ACTION_SEND` chooser; see `AndroidHistoryExporter`.
abstract interface class HistoryExporter {
  Future<void> shareCsv({required String subject, required String csv});
}
