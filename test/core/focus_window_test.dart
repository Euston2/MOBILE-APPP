import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/utils/focus_window.dart';

void main() {
  group('isOvernightLockWindow', () {
    test('starts at local midnight', () {
      expect(isOvernightLockWindow(DateTime(2026, 11, 3)), isTrue);
      expect(isOvernightLockWindow(DateTime(2026, 11, 3, 0, 0, 1)), isTrue);
    });

    test('stays active until one second before 08:00', () {
      expect(isOvernightLockWindow(DateTime(2026, 11, 3, 7, 59, 59)), isTrue);
    });

    test('ends exactly at 08:00', () {
      expect(isOvernightLockWindow(DateTime(2026, 11, 3, 8)), isFalse);
      expect(isOvernightLockWindow(DateTime(2026, 11, 3, 8, 0, 1)), isFalse);
    });

    test('is not active during the rest of the day', () {
      expect(isOvernightLockWindow(DateTime(2026, 11, 3, 12)), isFalse);
      expect(isOvernightLockWindow(DateTime(2026, 11, 3, 23, 59, 59)), isFalse);
    });
  });

  test('overnightLockEndFor returns 08:00 on the same local day', () {
    final end = overnightLockEndFor(DateTime(2026, 11, 3, 3, 17, 42));

    expect(end, DateTime(2026, 11, 3, 8));
  });
}
