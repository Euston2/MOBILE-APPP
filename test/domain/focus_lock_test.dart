import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/usecases/focus_lock.dart';

import '../helpers/fake_stores.dart';

void main() {
  final overnightNow = DateTime(2026, 11, 3, 3);
  final afterOvernight = DateTime(2026, 11, 3, 8);
  final studyEnd = DateTime(2026, 11, 3, 4, 30);
  final daytimeStudyEnd = DateTime(2026, 11, 3, 16, 30);

  group('isStudyLockActive', () {
    test('is true before the session end', () {
      final settings = settingsWith(studyEndsAt: studyEnd);

      expect(
        isStudyLockActive(
          settings,
          studyEnd.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });

    test('is false at and after the exact end instant', () {
      final settings = settingsWith(studyEndsAt: studyEnd);

      expect(isStudyLockActive(settings, studyEnd), isFalse);
      expect(
        isStudyLockActive(settings, studyEnd.add(const Duration(minutes: 1))),
        isFalse,
      );
    });

    test('is false when no session was started', () {
      expect(isStudyLockActive(settingsWith(), overnightNow), isFalse);
    });
  });

  group('isFocusLockActive', () {
    test('includes an enabled overnight lock inside its window', () {
      final settings = settingsWith(overnightLockEnabled: true);

      expect(isFocusLockActive(settings, overnightNow), isTrue);
      expect(isFocusLockActive(settings, afterOvernight), isFalse);
    });

    test('ignores the overnight window while the toggle is off', () {
      expect(isFocusLockActive(settingsWith(), overnightNow), isFalse);
    });

    test('stays active for a study session outside the overnight window', () {
      final settings = settingsWith(studyEndsAt: daytimeStudyEnd);

      expect(isFocusLockActive(settings, DateTime(2026, 11, 3, 15)), isTrue);
    });
  });

  group('canTurnOffOvernightLock', () {
    test('is false inside the active window', () {
      final settings = settingsWith(overnightLockEnabled: true);

      expect(canTurnOffOvernightLock(settings, overnightNow), isFalse);
    });

    test('is true outside the window or while already off', () {
      expect(
        canTurnOffOvernightLock(
          settingsWith(overnightLockEnabled: true),
          afterOvernight,
        ),
        isTrue,
      );
      expect(canTurnOffOvernightLock(settingsWith(), overnightNow), isTrue);
    });
  });

  group('activeFocusLockEnd', () {
    test('returns the overnight end while that window is active', () {
      final end = activeFocusLockEnd(
        settingsWith(overnightLockEnabled: true),
        overnightNow,
      );

      expect(end, DateTime(2026, 11, 3, 8));
    });

    test('returns the study end when both locks overlap', () {
      final end = activeFocusLockEnd(
        settingsWith(overnightLockEnabled: true, studyEndsAt: studyEnd),
        overnightNow,
      );

      expect(end, studyEnd);
    });

    test('falls back to overnight when the study session has expired', () {
      final end = activeFocusLockEnd(
        settingsWith(
          overnightLockEnabled: true,
          studyEndsAt: DateTime(2026, 11, 3, 2),
        ),
        overnightNow,
      );

      expect(end, DateTime(2026, 11, 3, 8));
    });

    test('is null when neither lock is active', () {
      expect(activeFocusLockEnd(settingsWith(), overnightNow), isNull);
    });
  });
}
