import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/entities/history_day.dart';
import 'package:lockout/domain/usecases/history_report.dart';

void main() {
  group('HistoryDay', () {
    test('flags a day that reached the limit exactly', () {
      final day = HistoryDay(
        date: DateTime(2026, 10, 30),
        totalSeconds: 3600,
        limitSeconds: 3600,
      );

      expect(day.hitLimit, isTrue);
      expect(day.overSeconds, 0);
      expect(day.remainingSeconds, 0);
    });

    test('reports time over and remaining under the limit', () {
      final over = HistoryDay(
        date: DateTime(2026, 10, 30),
        totalSeconds: 4200,
        limitSeconds: 3600,
      );
      expect(over.overSeconds, 600);
      expect(over.remainingSeconds, 0);

      final under = HistoryDay(
        date: DateTime(2026, 10, 30),
        totalSeconds: 1800,
        limitSeconds: 3600,
      );
      expect(under.overSeconds, 0);
      expect(under.remainingSeconds, 1800);
    });

    test('treats no limit as no overage and no remaining time', () {
      final day = HistoryDay(
        date: DateTime(2026, 10, 30),
        totalSeconds: 1200,
        limitSeconds: 0,
      );

      expect(day.hasLimit, isFalse);
      expect(day.hitLimit, isFalse);
      expect(day.overSeconds, 0);
      expect(day.remainingSeconds, 0);
    });

    test('hasUsage only when seconds were recorded', () {
      final empty = HistoryDay(
        date: DateTime(2026, 10, 30),
        totalSeconds: 0,
        limitSeconds: 3600,
      );
      expect(empty.hasUsage, isFalse);

      final used = HistoryDay(
        date: DateTime(2026, 10, 30),
        totalSeconds: 1,
        limitSeconds: 0,
      );
      expect(used.hasUsage, isTrue);
    });

    test('hasActivity includes focus-only and late-night-only days', () {
      final focus = HistoryDay(
        date: DateTime(2026, 10, 30),
        totalSeconds: 0,
        limitSeconds: 0,
        focusSeconds: 1500,
      );
      final late = HistoryDay(
        date: DateTime(2026, 10, 31),
        totalSeconds: 0,
        limitSeconds: 0,
        lateNightSeconds: 300,
      );
      final reading = HistoryDay(
        date: DateTime(2026, 11, 1),
        totalSeconds: 0,
        limitSeconds: 0,
        readingSeconds: 600,
      );

      expect(focus.hasUsage, isFalse);
      expect(focus.hasActivity, isTrue);
      expect(late.hasUsage, isFalse);
      expect(late.hasActivity, isTrue);
      expect(reading.hasUsage, isFalse);
      expect(reading.hasReading, isTrue);
      expect(reading.hasActivity, isTrue);
    });
  });

  group('buildHistoryReport', () {
    test('pads missing days and ends the day before endExclusive', () {
      final stored = [
        HistoryDay(
          date: DateTime(2026, 10, 28),
          totalSeconds: 3600,
          limitSeconds: 3600,
        ),
        HistoryDay(
          date: DateTime(2026, 10, 30),
          totalSeconds: 1800,
          limitSeconds: 3600,
          apps: const {'com.example.app': 1800},
        ),
      ];

      final report = buildHistoryReport(
        stored: stored,
        endExclusive: DateTime(2026, 10, 31),
        dayCount: 7,
      );

      expect(report.days, hasLength(7));
      expect(report.days.first.date, DateTime(2026, 10, 24));
      expect(report.days.last.date, DateTime(2026, 10, 30));
      expect(report.days[0].totalSeconds, 0);
      expect(report.days[4].dateKey, '2026-10-28');
      expect(report.days[4].totalSeconds, 3600);
      expect(report.days[6].apps, {'com.example.app': 1800});
      expect(report.hasData, isTrue);

      expect(report.stats.trackedDays, 2);
      expect(report.stats.totalSeconds, 5400);
      expect(report.stats.averageSeconds, 2700);
      expect(report.stats.limitHitDays, 1);
      expect(report.stats.underLimitDays, 1);
    });

    test('rolls the window across a month and year boundary', () {
      final report = buildHistoryReport(
        stored: const [],
        endExclusive: DateTime(2027, 1, 2),
        dayCount: 30,
      );

      expect(report.days, hasLength(30));
      expect(report.days.first.date, DateTime(2026, 12, 3));
      expect(report.days.last.date, DateTime(2027, 1, 1));
      expect(report.hasData, isFalse);
    });

    test('ignores stored days outside the requested window', () {
      final report = buildHistoryReport(
        stored: [
          HistoryDay(
            date: DateTime(2026, 10, 20),
            totalSeconds: 999,
            limitSeconds: 0,
          ),
          HistoryDay(
            date: DateTime(2026, 10, 30),
            totalSeconds: 600,
            limitSeconds: 0,
          ),
        ],
        endExclusive: DateTime(2026, 10, 31),
        dayCount: 7,
      );

      expect(report.stats.totalSeconds, 600);
      expect(report.days.first.date, DateTime(2026, 10, 24));
    });

    test('keeps focus-only days as data without counting them as usage', () {
      final report = buildHistoryReport(
        stored: [
          HistoryDay(
            date: DateTime(2026, 10, 30),
            totalSeconds: 0,
            limitSeconds: 0,
            focusSeconds: 1800,
            lateNightSeconds: 600,
          ),
        ],
        endExclusive: DateTime(2026, 10, 31),
        dayCount: 7,
      );

      expect(report.hasData, isTrue);
      expect(report.stats.trackedDays, 0);
      expect(report.stats.totalFocusSeconds, 1800);
      expect(report.stats.totalLateNightSeconds, 600);
    });

    test('treats zero-usage stored days as untracked', () {
      final report = buildHistoryReport(
        stored: [
          HistoryDay(
            date: DateTime(2026, 10, 30),
            totalSeconds: 0,
            limitSeconds: 3600,
          ),
        ],
        endExclusive: DateTime(2026, 10, 31),
        dayCount: 7,
      );

      expect(report.hasData, isFalse);
      expect(report.stats.trackedDays, 0);
      expect(report.stats.limitHitDays, 0);
      expect(report.stats.underLimitDays, 0);
    });

    test('attaches Reader time to stored and padded days', () {
      final report = buildHistoryReport(
        stored: [
          HistoryDay(
            date: DateTime(2026, 10, 30),
            totalSeconds: 1800,
            limitSeconds: 3600,
          ),
        ],
        endExclusive: DateTime(2026, 10, 31),
        dayCount: 7,
        readingSecondsByDay: const {
          '2026-10-30': 900,
          '2026-10-25': 300,
          '2026-10-20': 999,
        },
      );

      expect(report.days[6].readingSeconds, 900);
      expect(report.days[1].dateKey, '2026-10-25');
      expect(report.days[1].readingSeconds, 300);
      expect(report.stats.totalReadingSeconds, 1200);
      expect(report.stats.totalSeconds, 1800);
      expect(report.stats.trackedDays, 1);
    });

    test('counting-only days still count as history data', () {
      final report = buildHistoryReport(
        stored: const [],
        endExclusive: DateTime(2026, 10, 31),
        dayCount: 7,
        readingSecondsByDay: const {'2026-10-30': 1200},
      );

      expect(report.hasData, isTrue);
      expect(report.stats.totalReadingSeconds, 1200);
      expect(report.stats.trackedDays, 0);
      expect(report.days.last.hasReading, isTrue);
      expect(report.days.last.hasActivity, isTrue);
    });
  });

  group('summarizeHistory', () {
    test('averages tracked days only and counts limit days', () {
      final stats = summarizeHistory([
        HistoryDay(
          date: DateTime(2026, 10, 27),
          totalSeconds: 3600,
          limitSeconds: 3600,
          focusSeconds: 1800,
          lateNightSeconds: 300,
        ),
        HistoryDay(
          date: DateTime(2026, 10, 28),
          totalSeconds: 1800,
          limitSeconds: 3600,
          focusSeconds: 600,
          lateNightSeconds: 120,
        ),
        HistoryDay(
          date: DateTime(2026, 10, 29),
          totalSeconds: 1200,
          limitSeconds: 0,
        ),
        HistoryDay(
          date: DateTime(2026, 10, 30),
          totalSeconds: 0,
          limitSeconds: 3600,
          readingSeconds: 450,
        ),
      ]);

      expect(stats.trackedDays, 3);
      expect(stats.totalSeconds, 6600);
      expect(stats.averageSeconds, 2200);
      expect(stats.limitHitDays, 1);
      expect(stats.underLimitDays, 1);
      expect(stats.totalFocusSeconds, 2400);
      expect(stats.totalLateNightSeconds, 420);
      expect(stats.totalReadingSeconds, 450);
    });

    test('returns zeros for no days', () {
      final stats = summarizeHistory(const []);

      expect(stats.trackedDays, 0);
      expect(stats.totalSeconds, 0);
      expect(stats.averageSeconds, 0);
      expect(stats.limitHitDays, 0);
      expect(stats.underLimitDays, 0);
      expect(stats.totalFocusSeconds, 0);
      expect(stats.totalLateNightSeconds, 0);
      expect(stats.totalReadingSeconds, 0);
    });
  });
}
