import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/family_model.dart';

class SharedBudgetCard extends StatelessWidget {
  const SharedBudgetCard({super.key, required this.budget, this.onTap});

  final SharedBudgetModel budget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pct = budget.spentPercent;
    final barColor = pct >= 0.9
        ? AppColors.tertiary
        : pct >= 0.7
            ? AppColors.tertiary.withValues(alpha: 0.7)
            : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CategoryIcon(categoryName: budget.categoryName),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.name, style: AppTypography.titleSm),
                    Text(
                      budget.categoryName,
                      style: AppTypography.bodySm,
                    ),
                  ],
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: AppTypography.bodyMd.copyWith(color: barColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.format(budget.spent)} harcandı',
                style: AppTypography.bodySm,
              ),
              Text(
                CurrencyFormatter.format(budget.amount),
                style: AppTypography.bodySm,
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.categoryName});

  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: AppColors.primary,
        size: 20,
      ),
    );
  }
}
