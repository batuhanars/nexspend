import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/models/budget_model.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final BudgetPeriod selected;
  final ValueChanged<BudgetPeriod> onSelect;

  String _label(BudgetPeriod p, AppStrings s) => switch (p) {
    BudgetPeriod.MONTHLY => s.billingCycleMonthly,
    BudgetPeriod.WEEKLY => s.billingCycleWeekly,
    BudgetPeriod.YEARLY => s.billingCycleYearly,
    BudgetPeriod.CUSTOM => s.periodCustom,
  };

  // Görünüm sırası: Haftalık / Aylık / Yıllık / Özel
  static const _order = [
    BudgetPeriod.WEEKLY,
    BudgetPeriod.MONTHLY,
    BudgetPeriod.YEARLY,
    BudgetPeriod.CUSTOM,
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Row(
      children: _order.map((p) {
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
                _label(p, s),
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
