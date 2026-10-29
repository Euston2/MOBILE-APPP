import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/usecases/evaluate_limit.dart';

void main() {
  group('evaluateLimit', () {
    test('reports no limit when none is set', () {
      final status = evaluateLimit(usedSeconds: 1200, limitSeconds: 0);

      expect(status.hasLimit, isFalse);
      expect(status.isReached, isFalse);
      expect(status.remainingSeconds, 0);
      expect(status.overSeconds, 0);
      expect(status.progress, 0);
    });

    test('computes the remaining time while under the limit', () {
      final status = evaluateLimit(usedSeconds: 900, limitSeconds: 3600);

      expect(status.isReached, isFalse);
      expect(status.remainingSeconds, 2700);
      expect(status.overSeconds, 0);
      expect(status.progress, closeTo(0.25, 0.0001));
    });

    test('reaching the limit exactly counts as blocked', () {
      final status = evaluateLimit(usedSeconds: 3600, limitSeconds: 3600);

      expect(status.isReached, isTrue);
      expect(status.remainingSeconds, 0);
      expect(status.overSeconds, 0);
      expect(status.progress, 1);
    });

    test('reports time over the limit', () {
      final status = evaluateLimit(usedSeconds: 3900, limitSeconds: 3600);

      expect(status.isReached, isTrue);
      expect(status.overSeconds, 300);
      expect(status.remainingSeconds, 0);
      expect(status.progress, 1);
    });

    test('clamps negative values to zero', () {
      final status = evaluateLimit(usedSeconds: -60, limitSeconds: -1);

      expect(status.usedSeconds, 0);
      expect(status.limitSeconds, 0);
      expect(status.hasLimit, isFalse);
      expect(status.progress, 0);
    });
  });
}
