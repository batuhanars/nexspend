import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/models/budget_model.dart';

class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key, required this.budgets});
  final List<BudgetModel> budgets;

  @override
  Widget build(BuildContext context) {
    final exceededCount =
        budgets.where((b) => b.status == BudgetStatus.EXCEEDED).length;
    final criticalCount =
        budgets.where((b) => b.status == BudgetStatus.CRITICAL).length;

    if (exceededCount == 0 && criticalCount == 0) return const SizedBox.shrink();

    final isExceeded = exceededCount > 0;
    final color = isExceeded
        ? const Color(0xFFEF5350)
        : const Color(0xFFFF9800);
    final icon =
        isExceeded ? Icons.error_outline : Icons.warning_amber_outlined;
    final message = isExceeded
        ? AppStrings.of(context).budgetsExceeded(exceededCount)
        : AppStrings.of(context).budgetsCritical(criticalCount);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySm.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
