import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/inflation_keys.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/inflation_model.dart';

class InflationTrendChart extends StatelessWidget {
  const InflationTrendChart({super.key, required this.history});

  final Map<String, List<InflationRateModel>> history;

  static const _monthAbbr = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final genelRates = history[InflationCategoryKey.genel] ?? [];
    final gidaRates = history[InflationCategoryKey.gida] ?? [];

    if (genelRates.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Center(
          child: Text(
            'Trend verisi henüz hazır değil',
            style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }

    final spots = genelRates
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.monthlyRate))
        .toList();

    final gidaSpots = gidaRates.length == genelRates.length
        ? gidaRates
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.monthlyRate))
            .toList()
        : <FlSpot>[];

    final allRates = [
      ...genelRates.map((r) => r.monthlyRate),
      ...gidaRates.map((r) => r.monthlyRate),
    ];
    final maxY = allRates.isEmpty ? 10.0 : (allRates.reduce((a, b) => a > b ? a : b) * 1.3);

    final tooltipBg = colors.surfaceContainerHighest;
    final gridLineColor = colors.surfaceContainerHighest;
    final labelColor = colors.onSurfaceVariant;
    final primaryColor = colors.primary;
    final gidaColor = colors.expense;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LegendDot(color: primaryColor, label: 'Genel TÜFE'),
              if (gidaSpots.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.md),
                _LegendDot(color: gidaColor, label: 'Gıda'),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY > 0 ? maxY : 10,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => tooltipBg,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '%${s.y.toStringAsFixed(2)}',
                              AppTypography.bodySm.copyWith(color: s.bar.color),
                            ))
                        .toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= genelRates.length) {
                          return const SizedBox();
                        }
                        final rate = genelRates[i];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _monthAbbr[rate.month - 1],
                            style: AppTypography.labelSm.copyWith(
                              color: labelColor,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, _) => Text(
                        '%${value.toStringAsFixed(1)}',
                        style: AppTypography.labelSm.copyWith(
                          color: labelColor,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: gridLineColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: primaryColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryColor.withValues(alpha: 0.08),
                    ),
                  ),
                  if (gidaSpots.isNotEmpty)
                    LineChartBarData(
                      spots: gidaSpots,
                      isCurved: true,
                      color: gidaColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      dashArray: [4, 4],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
          ),
        ),
      ],
    );
  }
}
