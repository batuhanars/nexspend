import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/category_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/budget_model.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.budget,
    required this.onDelete,
    required this.onEdit,
    this.onTap,
  });
  final BudgetModel budget;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    final progress = (budget.percentage.clamp(0, 100) / 100).toDouble();
    final category = budget.category;

    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Icon(Icons.delete_outline, color: colors.error),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: colors.surfaceContainerHigh,
            title: Text(AppStrings.of(context).deleteBudgetTitle,
                style: AppTypography.titleSm),
            content: Text(
              AppStrings.of(context).deleteBudgetContent(budget.name),
              style: AppTypography.bodyMd
                  .copyWith(color: colors.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  AppStrings.of(context).cancel,
                  style: AppTypography.bodyMd.copyWith(color: colors.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  AppStrings.of(context).delete,
                  style: AppTypography.bodyMd.copyWith(color: colors.error),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: category?.cardColor.withValues(alpha: 0.15) ??
                          colors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconMapper.fromString(category?.icon ?? 'account_balance'),
                      color: category?.cardColor ?? colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(budget.name, style: AppTypography.titleSm),
                        if (category != null)
                          Text(
                            category.localizedName(context),
                            style: AppTypography.bodySm.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      budget.periodLabel(s),
                      style: AppTypography.labelSm.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(budget.statusColor),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    CurrencyFormatter.format(budget.spent),
                    style: AppTypography.bodySm.copyWith(
                      color: budget.statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    ' / ${CurrencyFormatter.format(budget.amount)}',
                    style: AppTypography.bodySm.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: budget.statusColor.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      '%${budget.percentage} · ${budget.statusLabel(s)}',
                      style: AppTypography.labelSm.copyWith(
                        color: budget.statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
