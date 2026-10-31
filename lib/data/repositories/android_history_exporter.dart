import '../../domain/repositories/history_exporter.dart';
import '../../platform/lockout_platform.dart';

/// Sends a history CSV through Android's system share sheet.
///
/// The CSV travels as plain text (`ACTION_SEND`), so the user can send it to
/// Mail, Drive, a notes app or a spreadsheet app without Lockout needing a file
/// provider or storage permission.
class AndroidHistoryExporter implements HistoryExporter {
  const AndroidHistoryExporter(this._platform);

  final LockoutPlatform _platform;

  @override
  Future<void> shareCsv({required String subject, required String csv}) =>
      _platform.shareText(subject: subject, text: csv);
}
