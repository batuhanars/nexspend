import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/utils/currency_formatter.dart';
import 'package:wallet_app/data/models/report_model.dart';

class CashFlowChart extends StatelessWidget {
  const CashFlowChart({super.key, required this.items});
  final List<CashFlowItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final s = AppStrings.of(context);
    final maxVal = items.expand((i) => [i.income, i.expense]).reduce(math.max);
    final topY = (maxVal * 1.2).ceilToDouble();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: BarChart(
        BarChartData(
          maxY: topY > 0 ? topY : 100,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceContainerHighest,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = rodIndex == 0 ? s.income : s.expense;
                return BarTooltipItem(
                  '$label\n${CurrencyFormatter.formatCompact(rod.toY)}',
                  AppTypography.bodySm.copyWith(
                    color: rodIndex == 0
                        ? AppColors.secondary
                        : AppColors.tertiary,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= items.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      items[i].label,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, _) => Text(
                  CurrencyFormatter.formatCompact(value),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.surfaceContainerHighest,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(items.length, (i) {
            final item = items[i];
            return BarChartGroupData(
              x: i,
              groupVertically: false,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: item.income,
                  color: AppColors.secondary,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: item.expense,
                  color: AppColors.tertiary,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
