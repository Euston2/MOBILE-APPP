import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/usecases/reading_goal.dart';

import '../helpers/fake_stores.dart';

void main() {
  final beforeCutoff = DateTime(2026, 11, 16, 19, 59);
  final atCutoff = DateTime(2026, 11, 16, 20);

  test('a goal is only configured above zero', () {
    expect(hasReadingGoal(settingsWith()), isFalse);
    expect(hasReadingGoal(settingsWith(readingGoalMinutes: 30)), isTrue);
    expect(readingGoalSeconds(settingsWith(readingGoalMinutes: 30)), 1800);
  });

  test('cutoff uses the local day and clamps bad values', () {
    expect(readingCutoffFor(beforeCutoff, 20 * 60), atCutoff);
    expect(
      readingCutoffFor(beforeCutoff, 25 * 60),
      DateTime(2026, 11, 16, 23, 59),
    );
    expect(readingCutoffFor(beforeCutoff, -10), DateTime(2026, 11, 16));
  });

  test('does not block before the cutoff', () {
    final settings = settingsWith(
      readingGoalMinutes: 30,
      readingAutoBlockEnabled: true,
    );

    expect(isReadingGoalBlockActive(settings, beforeCutoff, 0), isFalse);
  });

  test('blocks after the cutoff while the goal is short', () {
    final settings = settingsWith(
      readingGoalMinutes: 30,
      readingAutoBlockEnabled: true,
    );

    expect(isReadingGoalBlockActive(settings, atCutoff, 0), isTrue);
    expect(isReadingGoalBlockActive(settings, atCutoff, 1799), isTrue);
  });

  test('lifts once the goal is met', () {
    final settings = settingsWith(
      readingGoalMinutes: 30,
      readingAutoBlockEnabled: true,
    );

    expect(isReadingGoalBlockActive(settings, atCutoff, 1800), isFalse);
    expect(isReadingGoalBlockActive(settings, atCutoff, 3600), isFalse);
  });

  test('is disabled without a goal or without automation', () {
    final noGoal = settingsWith(readingAutoBlockEnabled: true);
    final noAutomation = settingsWith(readingGoalMinutes: 30);

    expect(isReadingGoalBlockActive(noGoal, atCutoff, 0), isFalse);
    expect(isReadingGoalBlockActive(noAutomation, atCutoff, 0), isFalse);
  });

  test('reports the remaining amount without going negative', () {
    final settings = settingsWith(readingGoalMinutes: 30);

    expect(readingGoalRemainingSeconds(settings, 0), 1800);
    expect(readingGoalRemainingSeconds(settings, 1200), 600);
    expect(readingGoalRemainingSeconds(settings, 1800), 0);
    expect(readingGoalRemainingSeconds(settings, 2400), 0);
  });

  test('the block ends at the next local midnight', () {
    expect(readingGoalBlockEnd(atCutoff), DateTime(2026, 11, 17));
  });
}
