import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/models/account_model.dart';

class AccountChips extends StatelessWidget {
  const AccountChips({
    super.key,
    required this.accounts,
    required this.selected,
    required this.onSelected,
  });
  final List<AccountModel> accounts;
  final AccountModel? selected;
  final ValueChanged<AccountModel> onSelected;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Text(
        AppStrings.of(context).noAccountsFound,
        style: AppTypography.bodySm
            .copyWith(color: AppColors.onSurfaceVariant),
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: accounts.map((a) {
        final isSelected = selected?.id == a.id;
        return GestureDetector(
          onTap: () => onSelected(a),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Text(
              a.name,
              style: AppTypography.bodyMd.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
