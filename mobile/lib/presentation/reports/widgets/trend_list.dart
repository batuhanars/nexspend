import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/utils/currency_formatter.dart';
import 'package:wallet_app/data/models/report_model.dart';

class TrendList extends StatelessWidget {
  const TrendList({super.key, required this.trends});
  final List<TrendItem> trends;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: trends.take(6).map((trend) {
        final isIncrease = trend.isIncrease;
        final color = isIncrease ? AppColors.tertiary : AppColors.secondary;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trend.categoryName,
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${CurrencyFormatter.formatCompact(trend.currentAmount)} (${AppStrings.of(context).previousLabel}: ${CurrencyFormatter.formatCompact(trend.previousAmount)})',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      isIncrease
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: color,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isIncrease ? '+' : ''}${trend.changePercent.toStringAsFixed(1)}%',
                      style: AppTypography.bodyMd.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
