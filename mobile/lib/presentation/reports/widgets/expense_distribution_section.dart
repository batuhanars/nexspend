import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/utils/currency_formatter.dart';
import 'package:wallet_app/core/utils/icon_mapper.dart';
import 'package:wallet_app/data/models/report_model.dart';

class ExpenseDistributionSection extends StatefulWidget {
  const ExpenseDistributionSection({super.key, required this.items});
  final List<ExpenseDistributionItem> items;

  @override
  State<ExpenseDistributionSection> createState() =>
      _ExpenseDistributionSectionState();
}

class _ExpenseDistributionSectionState
    extends State<ExpenseDistributionSection> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final items = widget.items.take(8).toList();
    final colors = _generateColors(items.length);

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: List.generate(items.length, (i) {
                    final isTouched = i == _touchedIndex;
                    return PieChartSectionData(
                      color: colors[i],
                      value: items[i].percentage,
                      title: isTouched
                          ? '${items[i].percentage.toStringAsFixed(1)}%'
                          : '',
                      radius: isTouched ? 40 : 32,
                      titleStyle: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  math.min(items.length, 5),
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[i],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            items[i].categoryName,
                            style: AppTypography.bodySm,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${items[i].percentage.toStringAsFixed(1)}%',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ...List.generate(items.length, (i) {
          final item = items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors[i].withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconMapper.fromString(item.categoryIcon),
                    size: 18,
                    color: colors[i],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.categoryName,
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        child: LinearProgressIndicator(
                          value: item.percentage / 100,
                          backgroundColor: colors[i].withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(colors[i]),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatCompact(item.amount),
                      style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${item.percentage.toStringAsFixed(1)}%',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<Color> _generateColors(int count) {
    const base = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiary,
      Color(0xFF7C9EFF),
      Color(0xFF50C8A8),
      Color(0xFFFFD580),
      Color(0xFFF28BCA),
      Color(0xFF95D5F5),
    ];
    return List.generate(count, (i) => base[i % base.length]);
  }
}
