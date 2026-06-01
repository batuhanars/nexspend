import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/theme/app_palette.dart';

class DuplicateWarning extends StatelessWidget {
  const DuplicateWarning({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppStrings.of(context).duplicateReceiptWarning,
              style: AppTypography.bodyMd.copyWith(color: colors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
