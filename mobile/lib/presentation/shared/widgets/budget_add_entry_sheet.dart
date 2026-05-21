import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';

enum BudgetAddEntryChoice { expense, receipt }

/// Bütçe / hesap detayında "Ekle" butonuna basıldığında açılan modal sheet.
/// Kullanıcının seçimi (işlem/fiş) `BudgetAddEntryChoice` ile döner, iptalde null.
///
/// `entryLabel` özelleştirilebilir — null ise default "Gider Ekle" (bütçe için).
/// Hesap detayında "İşlem Ekle" geçilir.
Future<BudgetAddEntryChoice?> showBudgetAddEntrySheet(
  BuildContext context, {
  String? entryLabel,
}) {
  return showModalBottomSheet<BudgetAddEntryChoice>(
    context: context,
    backgroundColor: AppColors.surfaceContainerHigh,
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
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _SheetActionTile(
              icon: Icons.add_card_outlined,
              label: entryLabel ?? AppStrings.of(sheetCtx).budgetSheetAddExpense,
              onTap: () =>
                  Navigator.pop(sheetCtx, BudgetAddEntryChoice.expense),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SheetActionTile(
              icon: Icons.document_scanner_outlined,
              label: AppStrings.of(sheetCtx).scanReceipt,
              onTap: () =>
                  Navigator.pop(sheetCtx, BudgetAddEntryChoice.receipt),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
