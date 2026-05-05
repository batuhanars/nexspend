import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account_analytics_model.dart';

class MonthlyChartSection extends StatelessWidget {
  const MonthlyChartSection({super.key, required this.months});
  final List<MonthlyFlowModel> months;

  String _abbr(String monthStr, BuildContext context) {
    final m = int.tryParse(monthStr.split('-').last) ?? 1;
    return AppStrings.of(context).monthAbbr(m.clamp(1, 12));
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = months.fold<double>(
      1,
      (m, e) => max(m, max(e.income, e.expense)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(AppStrings.of(context).lastSixMonths, style: AppTypography.titleSm),
              const Spacer(),
              ChartLegendDot(color: AppColors.secondary, label: AppStrings.of(context).incomeChartLabel),
              const SizedBox(width: AppSpacing.md),
              ChartLegendDot(color: AppColors.tertiary, label: AppStrings.of(context).expenseChartLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.3,
                barGroups: months.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        fromY: 0,
                        toY: e.value.income,
                        color: AppColors.secondary,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        fromY: 0,
                        toY: e.value.expense,
                        color: AppColors.tertiary,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _abbr(months[i].month, context),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceContainerHighest,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? AppStrings.of(context).incomeChartLabel : AppStrings.of(context).expenseChartLabel;
                      return BarTooltipItem(
                        '$label\n${CurrencyFormatter.formatCompact(rod.toY)}',
                        AppTypography.labelSm.copyWith(color: rod.color),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartLegendDot extends StatelessWidget {
  const ChartLegendDot({super.key, required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
