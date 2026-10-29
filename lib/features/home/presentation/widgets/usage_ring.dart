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
          SizedBox.square(
            dimension: size,
            child: CircularProgressIndicator(
              value: status.progress,
              strokeWidth: 14,
              strokeCap: StrokeCap.round,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatDuration(status.usedSeconds),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
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
