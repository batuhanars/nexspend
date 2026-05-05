import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';

class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final types = [
      (label: s.expense, value: 'EXPENSE', color: AppColors.tertiary),
      (label: s.income, value: 'INCOME', color: AppColors.secondary),
      (label: s.transfer, value: 'TRANSFER', color: AppColors.primary),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: types.map((t) {
          final isSelected = selected == t.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? t.color.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXl - 4),
                ),
                child: Center(
                  child: Text(
                    t.label,
                    style: AppTypography.bodyMd.copyWith(
                      color: isSelected ? t.color : AppColors.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
