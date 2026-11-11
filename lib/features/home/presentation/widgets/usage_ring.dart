import 'package:flutter/material.dart';

import '../../../../core/utils/duration_format.dart';
import '../../../../domain/usecases/evaluate_limit.dart';

/// Circular progress of today's usage against the limit.
///
/// Also used by the block screen so the number the user sees when blocked is
/// exactly the number they saw on Home.
class UsageRing extends StatelessWidget {
  const UsageRing({required this.status, this.size = 208, super.key});

  final LimitStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reached = status.isReached;
    final color = reached ? theme.colorScheme.error : theme.colorScheme.primary;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.12),
                    color.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.68, 1.0],
                ),
              ),
            ),
          ),
          SizedBox.square(
            dimension: size,
            child: CircularProgressIndicator(
              value: status.progress.isFinite
                  ? status.progress.clamp(0.0, 1.0)
                  : 0,
              strokeWidth: 11,
              strokeCap: StrokeCap.round,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'USED TODAY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                formatDuration(status.usedSeconds),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: reached ? color : theme.colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status.hasLimit
                    ? 'of ${formatDuration(status.limitSeconds)}'
                    : 'no limit set',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
