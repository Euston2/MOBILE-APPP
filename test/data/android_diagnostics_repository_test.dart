import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/data/repositories/android_diagnostics_repository.dart';
import 'package:lockout/domain/entities/device_diagnostics.dart';
import 'package:lockout/features/protection/presentation/diagnostics_report.dart';

void main() {
  group('AndroidDiagnosticsRepository.parse', () {
    test('parses a native snapshot and skips malformed events', () {
      final diagnostics = AndroidDiagnosticsRepository.parse({
        'manufacturer': 'Xiaomi',
        'brand': 'Redmi',
        'model': 'Note 12',
        'sdkInt': 33,
        'usageAccess': true,
        'overlay': true,
        'notifications': true,
        'batteryOptimizationIgnored': false,
        'exactAlarmsAllowed': true,
        'powerSaveMode': false,
        'serviceConfigured': true,
        'isLocked': true,
        'lockedAtMs': 1000,
        'nextResetAtMs': 2000,
        'limitSeconds': 3600,
        'monitoredCount': 2,
        'pendingConfigured': false,
        'lastArchivedDate': '',
        'events': [
          {'timestampMs': 1500, 'level': 'INFO', 'message': 'service started'},
          {'timestampMs': 0, 'level': 'INFO', 'message': 'ignored'},
          {'timestampMs': 2000, 'level': 'WARN', 'message': ''},
          'not a map',
        ],
      });

      expect(diagnostics.manufacturer, 'Xiaomi');
      expect(diagnostics.brand, 'Redmi');
      expect(diagnostics.model, 'Note 12');
      expect(diagnostics.sdkInt, 33);
      expect(diagnostics.usageAccess, isTrue);
      expect(diagnostics.overlay, isTrue);
      expect(diagnostics.notifications, isTrue);
      expect(diagnostics.batteryOptimizationIgnored, isFalse);
      expect(diagnostics.exactAlarmsAllowed, isTrue);
      expect(diagnostics.isLocked, isTrue);
      expect(diagnostics.lockedAt, DateTime.fromMillisecondsSinceEpoch(1000));
      expect(
        diagnostics.nextResetAt,
        DateTime.fromMillisecondsSinceEpoch(2000),
      );
      expect(diagnostics.limitSeconds, 3600);
      expect(diagnostics.monitoredCount, 2);
      expect(diagnostics.lastArchivedDate, isNull);
      expect(diagnostics.events, hasLength(1));
      expect(diagnostics.events.single.message, 'service started');
      expect(diagnostics.events.single.level, 'INFO');
      expect(diagnostics.passedRequiredChecks, 3);
      expect(diagnostics.allRequiredChecks, isFalse);
    });

    test('defaults missing values safely', () {
      final diagnostics = AndroidDiagnosticsRepository.parse(const {});

      expect(diagnostics.manufacturer, 'Android');
      expect(diagnostics.sdkInt, 0);
      expect(diagnostics.events, isEmpty);
      expect(diagnostics.passedRequiredChecks, 0);
      expect(diagnostics.nextResetAt, isNull);
    });
  });

  group('buildDiagnosticsReport', () {
    test('includes device, checks, enforcement and recent activity', () {
      final diagnostics = DeviceDiagnostics(
        manufacturer: 'Xiaomi',
        brand: 'Redmi',
        model: 'Note 12',
        sdkInt: 33,
        usageAccess: true,
        overlay: true,
        notifications: true,
        batteryOptimizationIgnored: false,
        exactAlarmsAllowed: false,
        serviceConfigured: true,
        isLocked: false,
        nextResetAt: DateTime(2026, 11, 2),
        limitSeconds: 3600,
        monitoredCount: 2,
        pendingConfigured: true,
        lastArchivedDate: '2026-10-31',
        events: [
          DiagnosticEvent(
            at: DateTime(2026, 10, 31, 12, 3, 4),
            level: 'INFO',
            message: 'service started',
          ),
        ],
      );

      final report = buildDiagnosticsReport(diagnostics);

      expect(report, contains('Lockout support report'));
      expect(report, contains('Device: Xiaomi Note 12 (Android SDK 33)'));
      expect(report, contains('Setup checks: 3/4'));
      expect(report, contains('Battery saver exemption: no'));
      expect(report, contains('Scheduled change: yes'));
      expect(report, contains('Last archived day: 2026-10-31'));
      expect(report, contains('2026-10-31 12:03:04 INFO service started'));
    });

    test('marks an empty event log explicitly', () {
      final report = buildDiagnosticsReport(const DeviceDiagnostics());

      expect(report, contains('Recent activity:\n  (none)'));
    });
  });

  group('friendly diagnostics', () {
    DiagnosticEvent event(String level, String message) => DiagnosticEvent(
      at: DateTime(2026, 10, 31),
      level: level,
      message: message,
    );

    test('maps native events to plain-language activity', () {
      expect(
        friendlyDiagnosticMessage(event('INFO', 'service started: 2 apps')),
        'Protection started',
      );
      expect(
        friendlyDiagnosticMessage(event('INFO', 'service start requested')),
        'Protection starting',
      );
      expect(
        friendlyDiagnosticMessage(event('WARN', 'could not restart watcher')),
        'Protection needs a restart',
      );
      expect(
        friendlyDiagnosticMessage(event('ERROR', 'something unexpected')),
        'Something went wrong',
      );
    });

    test('maps log levels to friendly labels', () {
      expect(friendlyDiagnosticLevel('INFO'), 'Update');
      expect(friendlyDiagnosticLevel('WARN'), 'Notice');
      expect(friendlyDiagnosticLevel('ERROR'), 'Issue');
    });
  });
}
