import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/duration_format.dart';
import '../../../../domain/entities/history_day.dart';
import '../history_format.dart';

/// Grouped bars comparing social-app screen time, focus time and late-night
/// social usage for each archived day.
///
/// Late-night is a subset of social time: it counts the selected apps from
/// local 00:00 to 08:00. Focus time is the cumulative timer total for the day.
class FocusComparisonChart extends StatelessWidget {
  const FocusComparisonChart({required this.days, super.key});

  final List<HistoryDay> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    final peakMinutes = days.fold<double>(
      0,
      (peak, day) => math.max(
        peak,
        math.max(
              day.totalSeconds,
              math.max(day.focusSeconds, day.lateNightSeconds),
            ) /
            60,
      ),
    );
    final maxY = math.max(30.0, peakMinutes * 1.2);
    final interval = _intervalFor(maxY);
    final barWidth = days.length <= 7 ? 8.0 : 3.5;
    final barsSpace = days.length <= 7 ? 3.0 : 1.0;

    return Semantics(
      label:
          'Social time, focus time and late-night usage chart, '
          '${rangeLabel(days)}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    for (var index = 0; index < days.length; index++)
                      BarChartGroupData(
                        x: index,
                        barsSpace: barsSpace,
                        barRods: [
                          _rod(
                            days[index].totalSeconds / 60,
                            colors.primary,
                            barWidth,
                          ),
                          _rod(
                            days[index].focusSeconds / 60,
                            colors.tertiary,
                            barWidth,
                          ),
                          _rod(
                            days[index].lateNightSeconds / 60,
                            colors.error,
                            barWidth,
                          ),
                        ],
                      ),
                  ],
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.outlineVariant.withValues(alpha: 0.35),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        interval: interval,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          space: 6,
                          child: Text(
                            formatDuration((value * 60).round()),
                            style: labelStyle,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= days.length) {
                            return const SizedBox.shrink();
                          }
                          final show =
                              days.length <= 7 ||
                              index % 5 == 0 ||
                              index == days.length - 1;
                          if (!show) return const SizedBox.shrink();

                          final date = days[index].date;
                          return SideTitleWidget(
                            meta: meta,
                            space: 6,
                            child: Text(
                              days.length <= 7
                                  ? weekdayShort(date)
                                  : '${date.day}',
                              style: labelStyle,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      maxContentWidth: 190,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      getTooltipColor: (group) => colors.inverseSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final index = group.x;
                        if (index < 0 || index >= days.length) return null;
                        final day = days[index];
                        final (label, seconds) = switch (rodIndex) {
                          0 => ('Social', day.totalSeconds),
                          1 => ('Focus', day.focusSeconds),
                          _ => ('Late night', day.lateNightSeconds),
                        };
                        return BarTooltipItem(
                          '${longDate(day.date)}\n'
                          '$label · ${formatDuration(seconds)}',
                          TextStyle(
                            color: colors.onInverseSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LegendDot(color: colors.primary, label: 'Social screen time'),
                _LegendDot(color: colors.tertiary, label: 'Focus time'),
                _LegendDot(color: colors.error, label: 'Late night (12-8 AM)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BarChartRodData _rod(double value, Color color, double width) =>
      BarChartRodData(
        toY: value,
        width: width,
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      );

  double _intervalFor(double maxY) {
    if (maxY <= 30) return 10;
    if (maxY <= 60) return 15;
    if (maxY <= 120) return 30;
    if (maxY <= 300) return 60;
    if (maxY <= 720) return 120;
    return 240;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
