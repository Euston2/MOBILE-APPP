/// How today's usage compares with the limit.
///
/// Pure value object: the Home ring, the block screen (Stage 3) and the lock
/// checks (Stage 4) all derive from this one calculation.
class LimitStatus {
  const LimitStatus({required this.usedSeconds, required this.limitSeconds});

  final int usedSeconds;
  final int limitSeconds;

  bool get hasLimit => limitSeconds > 0;

  /// Reaching the limit exactly counts as blocked.
  bool get isReached => hasLimit && usedSeconds >= limitSeconds;

  /// Seconds left before the limit; 0 when reached or no limit is set.
  int get remainingSeconds {
    if (!hasLimit) return 0;
    final remaining = limitSeconds - usedSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Seconds over the limit; 0 when under.
  int get overSeconds {
    if (!hasLimit) return 0;
    final over = usedSeconds - limitSeconds;
    return over > 0 ? over : 0;
  }

  /// 0..1 for the progress ring.
  double get progress {
    if (!hasLimit) return 0;
    final ratio = usedSeconds / limitSeconds;
    return ratio.clamp(0.0, 1.0);
  }
}

/// Builds the [LimitStatus] for today's usage.
LimitStatus evaluateLimit({
  required int usedSeconds,
  required int limitSeconds,
}) {
  return LimitStatus(
    usedSeconds: usedSeconds < 0 ? 0 : usedSeconds,
    limitSeconds: limitSeconds < 0 ? 0 : limitSeconds,
  );
}
