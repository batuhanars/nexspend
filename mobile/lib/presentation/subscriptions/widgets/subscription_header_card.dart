import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/subscription_model.dart';

class SubscriptionHeaderCard extends StatelessWidget {
  const SubscriptionHeaderCard({super.key, required this.sub});
  final SubscriptionModel sub;

  @override
  Widget build(BuildContext context) {
    final color = sub.cardColor;
    final s = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(Icons.subscriptions_outlined, color: color, size: 32),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            CurrencyFormatter.format(sub.amount),
            style: AppTypography.headlineMd.copyWith(color: color),
          ),
          Text(sub.billingCycle.label(s), style: AppTypography.bodySm),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: sub.isActive
                  ? AppColors.secondary.withValues(alpha: 0.12)
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              sub.isActive ? s.activeLabel : s.inactiveLabel,
              style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.w600,
                color: sub.isActive
                    ? AppColors.secondary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
