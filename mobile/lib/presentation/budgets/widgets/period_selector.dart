import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/budget_model.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key, required this.selected, required this.onSelect});
  final BudgetPeriod selected;
  final ValueChanged<BudgetPeriod> onSelect;

  static const _labels = {
    BudgetPeriod.MONTHLY: 'Aylık',
    BudgetPeriod.WEEKLY: 'Haftalık',
    BudgetPeriod.YEARLY: 'Yıllık',
    BudgetPeriod.CUSTOM: 'Özel',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: BudgetPeriod.values.map((p) {
        final isSelected = p == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                right: p != BudgetPeriod.CUSTOM ? AppSpacing.sm : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                _labels[p]!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
