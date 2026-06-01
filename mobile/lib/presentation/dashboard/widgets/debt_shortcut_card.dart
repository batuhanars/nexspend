import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';

class DebtShortcutCard extends StatelessWidget {
  const DebtShortcutCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.handshake_outlined,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(s.myDebts, style: AppTypography.titleSm),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colors.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
