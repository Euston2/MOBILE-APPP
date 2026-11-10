import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/utils/day_window.dart';
import 'package:lockout/domain/entities/usage_settings.dart';
import 'package:lockout/domain/usecases/study_timer.dart';

import '../helpers/fake_stores.dart';

void main() {
  final today = DateTime(2026, 11, 9);
  final todayKey = localDateKey(today);

  group('focusSecondsForToday', () {
    test('uses the banked total only on the matching local date', () {
      final current = settingsWith(
        focusDate: todayKey,
        focusSecondsToday: 1200,
      );
      final stale = settingsWith(
        focusDate: localDateKey(today.subtract(const Duration(days: 1))),
        focusSecondsToday: 1200,
      );

      expect(focusSecondsForToday(current, DateTime(2026, 11, 9, 10)), 1200);
      expect(focusSecondsForToday(stale, DateTime(2026, 11, 9, 10)), 0);
    });

    test('adds the elapsed part of a running session', () {
      final settings = settingsWith(
        focusDate: todayKey,
        focusSecondsToday: 600,
        focusSessionStartedAt: DateTime(2026, 11, 9, 9, 50),
        focusSessionEndsAt: DateTime(2026, 11, 9, 10, 20),
        focusSessionRemainingSeconds: 1800,
      );

      expect(
        focusSecondsForToday(settings, DateTime(2026, 11, 9, 10)),
        600 + 10 * 60,
      );
    });

    test('caps a running session at its end', () {
      final settings = settingsWith(
        focusDate: todayKey,
        focusSessionStartedAt: DateTime(2026, 11, 9, 9, 50),
        focusSessionEndsAt: DateTime(2026, 11, 9, 10, 20),
      );

      expect(
        focusSecondsForToday(settings, DateTime(2026, 11, 9, 10, 40)),
        30 * 60,
      );
    });

    test('counts only the part inside the current local day', () {
      final settings = settingsWith(
        focusDate: todayKey,
        focusSessionStartedAt: DateTime(2026, 11, 8, 23, 50),
        focusSessionEndsAt: DateTime(2026, 11, 9, 0, 20),
      );

      expect(
        focusSecondsForToday(settings, DateTime(2026, 11, 9, 0, 10)),
        10 * 60,
      );
    });
  });

  group('focus session state', () {
    test('is running until its exact end', () {
      final settings = settingsWith(
        focusSessionStartedAt: DateTime(2026, 11, 9, 10),
        focusSessionEndsAt: DateTime(2026, 11, 9, 10, 25),
      );

      expect(
        isFocusSessionRunning(settings, DateTime(2026, 11, 9, 10)),
        isTrue,
      );
      expect(
        isFocusSessionRunning(settings, DateTime(2026, 11, 9, 10, 24, 59)),
        isTrue,
      );
      expect(
        isFocusSessionRunning(settings, DateTime(2026, 11, 9, 10, 25)),
        isFalse,
      );
      expect(
        focusSessionRemainingSeconds(settings, DateTime(2026, 11, 9, 10)),
        25 * 60,
      );
    });

    test('is paused only with a saved countdown and no running bounds', () {
      final paused = settingsWith(focusSessionRemainingSeconds: 300);

      expect(isFocusSessionPaused(paused, DateTime(2026, 11, 9, 10)), isTrue);
      expect(
        focusSessionRemainingSeconds(paused, DateTime(2026, 11, 9, 10)),
        300,
      );
      expect(
        isFocusSessionPaused(settingsWith(), DateTime(2026, 11, 9, 10)),
        isFalse,
      );
    });
  });

  group('focus goal automation', () {
    final afterCutoff = DateTime(2026, 11, 9, 20);
    final beforeCutoff = DateTime(2026, 11, 9, 19, 59);

    UsageSettings goalSettings({
      bool auto = true,
      int goalMinutes = 60,
      int cutoffMinutes = 20 * 60,
      int focusSeconds = 0,
      DateTime? sessionStart,
      DateTime? sessionEnd,
    }) => settingsWith(
      focusGoalMinutes: goalMinutes,
      focusAutoBlockEnabled: auto,
      focusCutoffMinutes: cutoffMinutes,
      focusDate: todayKey,
      focusSecondsToday: focusSeconds,
      focusSessionStartedAt: sessionStart,
      focusSessionEndsAt: sessionEnd,
    );

    test('starts at the cutoff when the goal is still short', () {
      final settings = goalSettings();

      expect(isFocusGoalBlockActive(settings, beforeCutoff), isFalse);
      expect(isFocusGoalBlockActive(settings, afterCutoff), isTrue);
      expect(isFocusGoalMet(settings, afterCutoff), isFalse);
    });

    test('lifts early as soon as cumulative focus reaches the goal', () {
      final settings = goalSettings(focusSeconds: 60 * 60);

      expect(isFocusGoalMet(settings, afterCutoff), isTrue);
      expect(isFocusGoalBlockActive(settings, afterCutoff), isFalse);
    });

    test('a running session can close the gap before it is banked', () {
      final settings = goalSettings(
        focusSeconds: 40 * 60,
        sessionStart: DateTime(2026, 11, 9, 19, 40),
        sessionEnd: DateTime(2026, 11, 9, 20, 10),
      );

      expect(isFocusGoalBlockActive(settings, beforeCutoff), isFalse);
      expect(isFocusGoalBlockActive(settings, afterCutoff), isFalse);
    });

    test(
      'requires automation, a goal and selected apps at the native layer',
      () {
        expect(
          isFocusGoalBlockActive(goalSettings(auto: false), afterCutoff),
          isFalse,
        );
        expect(
          isFocusGoalBlockActive(goalSettings(goalMinutes: 0), afterCutoff),
          isFalse,
        );
      },
    );

    test('a cutoff of midnight applies immediately', () {
      final settings = goalSettings(cutoffMinutes: 0);

      expect(isFocusGoalBlockActive(settings, DateTime(2026, 11, 9)), isTrue);
    });

    test('the block ends at the next local midnight', () {
      expect(focusGoalBlockEnd(afterCutoff), DateTime(2026, 11, 10));
    });
  });

  group('focusCutoffFor', () {
    test('uses the requested local minute', () {
      expect(
        focusCutoffFor(DateTime(2026, 11, 9, 15, 30), 21 * 60 + 15),
        DateTime(2026, 11, 9, 21, 15),
      );
    });

    test('clamps invalid minute values into the day', () {
      final moment = DateTime(2026, 11, 9, 15, 30);

      expect(focusCutoffFor(moment, -10), DateTime(2026, 11, 9));
      expect(
        focusCutoffFor(moment, 24 * 60 + 10),
        DateTime(2026, 11, 9, 23, 59),
      );
    });
  });
}
