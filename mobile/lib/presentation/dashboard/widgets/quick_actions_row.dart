import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    required this.onIncome,
    required this.onExpense,
    required this.onTransfer,
    required this.onScan,
  });

  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final VoidCallback onTransfer;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionButton(
            icon: Icons.add_rounded,
            label: s.income,
            color: colors.secondary,
            onTap: onIncome,
          ),
          _ActionButton(
            icon: Icons.remove_rounded,
            label: s.expense,
            color: colors.tertiary,
            onTap: onExpense,
          ),
          _ActionButton(
            icon: Icons.swap_horiz_rounded,
            label: s.transfer,
            color: colors.primary,
            onTap: onTransfer,
          ),
          _ActionButton(
            icon: Icons.document_scanner_outlined,
            label: s.scanAction,
            color: colors.onSurfaceVariant,
            onTap: onScan,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelMd.copyWith(color: context.colors.onSurface),
          ),
        ],
      ),
    );
  }
}
