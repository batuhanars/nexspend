import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account_analytics_model.dart';

class ThisMonthSection extends StatelessWidget {
  const ThisMonthSection({super.key, required this.analytics});
  final AccountAnalyticsModel analytics;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isCreditCard = analytics.isCreditCard;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.periodThisMonth, style: AppTypography.titleSm),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FlowChip(
                  label: isCreditCard ? s.paymentLabel : s.income,
                  amount: isCreditCard
                      ? analytics.currentMonthPayment
                      : analytics.currentMonthIncome,
                  color: AppColors.secondary,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FlowChip(
                  label: isCreditCard ? s.spendChartLabel : s.expense,
                  amount: isCreditCard
                      ? analytics.currentMonthSpend
                      : analytics.currentMonthExpense,
                  color: AppColors.tertiary,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FlowChip extends StatelessWidget {
  const FlowChip({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: AppTypography.labelSm.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: AppTypography.titleSm,
          ),
        ],
      ),
    );
  }
}
