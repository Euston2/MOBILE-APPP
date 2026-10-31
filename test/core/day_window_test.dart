import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/utils/day_window.dart';

void main() {
  group('startOfLocalDay', () {
    test('returns midnight of the same local day', () {
      final moment = DateTime(2026, 10, 29, 15, 4, 30);

      expect(startOfLocalDay(moment), DateTime(2026, 10, 29));
    });

    test('is idempotent on a midnight value', () {
      final midnight = DateTime(2026, 1, 1);

      expect(startOfLocalDay(midnight), midnight);
    });
  });

  group('nextLocalMidnight', () {
    test('rolls over a normal day', () {
      expect(
        nextLocalMidnight(DateTime(2026, 10, 29, 23, 59)),
        DateTime(2026, 10, 30),
      );
    });

    test('rolls over the end of a month and year', () {
      expect(
        nextLocalMidnight(DateTime(2026, 12, 31, 22)),
        DateTime(2027, 1, 1),
      );
    });

    test('rolls over February in a leap year', () {
      expect(
        nextLocalMidnight(DateTime(2028, 2, 28, 12)),
        DateTime(2028, 2, 29),
      );
    });
  });

  group('untilNextMidnight', () {
    test('counts the remaining time of the day', () {
      expect(
        untilNextMidnight(DateTime(2026, 10, 29, 23, 0)),
        const Duration(hours: 1),
      );
    });

    test('returns a full day at midnight (reset is the next midnight)', () {
      expect(
        untilNextMidnight(DateTime(2026, 10, 29)),
        const Duration(hours: 24),
      );
    });
  });

  group('localDateKey', () {
    test('pads month and day', () {
      expect(localDateKey(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
    });

    test('round-trips through parseLocalDateKey', () {
      final date = DateTime(2026, 10, 30);
      expect(parseLocalDateKey(localDateKey(date)), date);
    });
  });

  group('parseLocalDateKey', () {
    test('rejects malformed keys', () {
      expect(parseLocalDateKey('2026-2-03'), isNull);
      expect(parseLocalDateKey('2026/10/30'), isNull);
      expect(parseLocalDateKey('not-a-date'), isNull);
      expect(parseLocalDateKey(''), isNull);
    });

    test('rejects impossible calendar dates', () {
      expect(parseLocalDateKey('2026-02-30'), isNull);
      expect(parseLocalDateKey('2026-13-01'), isNull);
    });

    test('accepts a leap day', () {
      expect(parseLocalDateKey('2028-02-29'), DateTime(2028, 2, 29));
    });
  });
}
