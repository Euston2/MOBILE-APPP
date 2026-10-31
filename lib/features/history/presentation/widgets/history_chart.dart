import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/duration_format.dart';
import '../../../../domain/entities/history_day.dart';
import '../history_format.dart';

/// One bar per archived day, in minutes, with a dashed line for a limit that
/// was unchanged across the window.
///
/// Missing days are already zero-padded by the domain report, so the x axis
/// always represents real calendar days rather than "days with data".
class HistoryChart extends StatelessWidget {
  const HistoryChart({required this.days, super.key});

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
      (peak, day) =>
          math.max(peak, math.max(day.totalSeconds, day.limitSeconds) / 60),
    );
    // Keep a small usage bar visible on a sensible scale instead of blowing it
    // up to the full chart height.
    final maxY = math.max(60.0, peakMinutes * 1.2);
    final interval = _intervalFor(maxY);

    // Only draw the limit guide when there was one consistent limit: a changed
    // limit would make older bars look as if they were judged by the new value.
    final limits = days
        .where((day) => day.hasLimit)
        .map((day) => day.limitSeconds)
        .toSet();
    final uniformLimit = limits.length == 1 ? limits.first : null;

    return Semantics(
      label: 'Daily usage chart, ${rangeLabel(days)}',
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barGroups: [
            for (var index = 0; index < days.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: days[index].totalSeconds / 60,
                    width: days.length <= 7 ? 18 : 7,
                    color: days[index].hitLimit ? colors.error : colors.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
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
                  // Seven days can label every bar; a month only every fifth
                  // day plus the last one, otherwise labels collide.
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
                      days.length <= 7 ? weekdayShort(date) : '${date.day}',
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
              maxContentWidth: 160,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              getTooltipColor: (group) => colors.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final index = group.x;
                if (index < 0 || index >= days.length) return null;
                final day = days[index];
                return BarTooltipItem(
                  '${longDate(day.date)}\n${formatDuration(day.totalSeconds)}',
                  TextStyle(
                    color: colors.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (uniformLimit != null)
                HorizontalLine(
                  y: uniformLimit / 60,
                  color: colors.error.withValues(alpha: 0.6),
                  strokeWidth: 1,
                  dashArray: const [4, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 4, bottom: 2),
                    style: labelStyle?.copyWith(color: colors.error),
                    labelResolver: (_) => 'limit',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _intervalFor(double maxY) {
    if (maxY <= 60) return 15;
    if (maxY <= 120) return 30;
    if (maxY <= 300) return 60;
    if (maxY <= 720) return 120;
    return 240;
  }
}
