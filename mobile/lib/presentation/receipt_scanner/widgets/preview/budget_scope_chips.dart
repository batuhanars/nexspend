import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../data/models/family_model.dart';
import '../../bloc/receipt_preview_bloc.dart';

/// Fiş preview ekranında kategori seçildikten sonra çıkar:
/// "Kişisel" + kullanıcının o kategori için üyesi olduğu ortak bütçeler.
class BudgetScopeChips extends StatelessWidget {
  const BudgetScopeChips({super.key, required this.state});
  final ReceiptPreviewReady state;

  @override
  Widget build(BuildContext context) {
    final budgets = state.sharedBudgetsForSelectedCategory;
    if (budgets.isEmpty) return const SizedBox.shrink();
    final personalLabel = AppStrings.of(context).budgetScopePersonal;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _Chip(
          label: personalLabel,
          selected: state.selectedSharedBudgetId == null,
          onTap: () => context
              .read<ReceiptPreviewBloc>()
              .add(const ReceiptPreviewSharedBudgetSelected(null)),
        ),
        for (final MySharedBudgetModel b in budgets)
          _Chip(
            label: '${b.groupName} · ${b.name}',
            selected: state.selectedSharedBudgetId == b.id,
            onTap: () => context
                .read<ReceiptPreviewBloc>()
                .add(ReceiptPreviewSharedBudgetSelected(b.id)),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Text(
          label,
          style: AppTypography.bodySm.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
