import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class EmptyBudgetsView extends StatelessWidget {
  const EmptyBudgetsView({super.key, required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 72,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Henüz bütçe yok',
            style: AppTypography.titleSm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Harcamalarını takip etmek için\nbir bütçe oluştur.',
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              minimumSize: const Size(160, 48),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Bütçe Oluştur'),
          ),
        ],
      ),
    );
  }
}
