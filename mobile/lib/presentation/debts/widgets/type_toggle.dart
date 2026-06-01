import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/data/models/debt_model.dart';

class TypeToggle extends StatelessWidget {
  const TypeToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final DebtType selected;
  final ValueChanged<DebtType> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = AppStrings.of(context);
    final types = [
      (label: s.debtTypeBorrowed, value: DebtType.BORROWED, color: colors.expense),
      (label: s.debtTypeLent, value: DebtType.LENT, color: colors.income),
    ];
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl - 4),
                ),
                child: Center(
                  child: Text(
                    t.label,
                    style: AppTypography.bodyMd.copyWith(
                      color: isSelected ? t.color : colors.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
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
