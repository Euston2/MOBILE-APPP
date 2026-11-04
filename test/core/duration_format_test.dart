import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/utils/duration_format.dart';

void main() {
  group('formatDuration', () {
    test('formats zero and sub-minute values', () {
      expect(formatDuration(0), '0m');
      expect(formatDuration(30), '<1m');
      expect(formatDuration(-10), '0m');
    });

    test('formats minutes', () {
      expect(formatDuration(60), '1m');
      expect(formatDuration(3599), '59m');
    });

    test('formats hours with zero-padded minutes', () {
      expect(formatDuration(3600), '1h');
      expect(formatDuration(3900), '1h 05m');
      expect(formatDuration(86399), '23h 59m');
    });
  });

  group('formatClockTime', () {
    test('formats midnight and noon as 12', () {
      expect(formatClockTime(DateTime(2026, 11, 3)), '12:00 AM');
      expect(formatClockTime(DateTime(2026, 11, 3, 12)), '12:00 PM');
    });

    test('formats morning and evening times with padded minutes', () {
      expect(formatClockTime(DateTime(2026, 11, 3, 8)), '8:00 AM');
      expect(formatClockTime(DateTime(2026, 11, 3, 13, 5)), '1:05 PM');
      expect(formatClockTime(DateTime(2026, 11, 3, 23, 59)), '11:59 PM');
    });
  });

  group('formatCountdown', () {
    test('shows seconds under a minute', () {
      expect(formatCountdown(const Duration(seconds: 45)), '45s');
    });

    test('shows minutes under an hour', () {
      expect(formatCountdown(const Duration(minutes: 12, seconds: 30)), '12m');
    });

    test('shows hours and minutes', () {
      expect(formatCountdown(const Duration(hours: 3, minutes: 12)), '3h 12m');
    });

    test('never goes negative', () {
      expect(formatCountdown(const Duration(minutes: -5)), '0s');
      expect(formatCountdown(Duration.zero), '0s');
    });
  });
}
