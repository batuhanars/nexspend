import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';

enum BudgetCreateChoice { budget, group }

/// Bütçeler ekranındaki "+" butonuna basıldığında açılan modal sheet.
Future<BudgetCreateChoice?> showBudgetCreateSheet(BuildContext context) {
  final colors = context.colors;
  return showModalBottomSheet<BudgetCreateChoice>(
    context: context,
    backgroundColor: colors.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
    ),
    builder: (sheetCtx) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: sheetCtx.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _SheetActionTile(
              icon: Icons.savings_outlined,
              label: AppStrings.of(sheetCtx).budgetCreateSheetBudget,
              onTap: () =>
                  Navigator.pop(sheetCtx, BudgetCreateChoice.budget),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SheetActionTile(
              icon: Icons.group_outlined,
              label: AppStrings.of(sheetCtx).budgetCreateSheetGroup,
              onTap: () =>
                  Navigator.pop(sheetCtx, BudgetCreateChoice.group),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetActionTile extends StatelessWidget {
  const _SheetActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMd.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
