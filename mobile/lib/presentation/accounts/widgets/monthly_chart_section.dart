import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account_analytics_model.dart';

class MonthlyChartSection extends StatelessWidget {
  const MonthlyChartSection({
    super.key,
    required this.months,
    this.isCreditCard = false,
  });
  final List<MonthlyFlowModel> months;
  final bool isCreditCard;

  String _abbr(String monthStr, BuildContext context) {
    final m = int.tryParse(monthStr.split('-').last) ?? 1;
    return AppStrings.of(context).monthAbbr(m.clamp(1, 12));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = AppStrings.of(context);
    final maxVal = months.fold<double>(
      1,
      (m, e) => isCreditCard
          ? max(m, max(e.payment ?? 0, e.spend ?? 0))
          : max(m, max(e.income, e.expense)),
    );

    final primaryLabel = isCreditCard ? s.paymentLabel : s.incomeChartLabel;
    final secondaryLabel = isCreditCard ? s.spendChartLabel : s.expenseChartLabel;
    final tooltipBg = colors.surfaceContainerHighest;
    final labelColor = colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s.lastSixMonths, style: AppTypography.titleSm),
              const Spacer(),
              ChartLegendDot(color: colors.income, label: primaryLabel),
              const SizedBox(width: AppSpacing.md),
              ChartLegendDot(color: colors.expense, label: secondaryLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.3,
                barGroups: months.asMap().entries.map((e) {
                  final primaryVal =
                      isCreditCard ? (e.value.payment ?? 0) : e.value.income;
                  final secondaryVal =
                      isCreditCard ? (e.value.spend ?? 0) : e.value.expense;
                  return BarChartGroupData(
                    x: e.key,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        fromY: 0,
                        toY: primaryVal,
                        color: colors.income,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        fromY: 0,
                        toY: secondaryVal,
                        color: colors.expense,
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
                            color: labelColor,
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
                    getTooltipColor: (_) => tooltipBg,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label =
                          rodIndex == 0 ? primaryLabel : secondaryLabel;
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
            color: context.colors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
