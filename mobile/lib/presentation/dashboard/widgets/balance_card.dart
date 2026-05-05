import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/dashboard_model.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.dashboard,
    required this.isBalanceHidden,
    required this.onToggleVisibility,
  });

  final DashboardModel dashboard;
  final bool isBalanceHidden;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final isPositive = dashboard.monthlyChange >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C6BC0), Color(0xFF3C4C9F)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.of(context).totalAssets,
                style: AppTypography.labelSm.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onToggleVisibility,
                child: Icon(
                  isBalanceHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          isBalanceHidden
              ? Text(
                  '₺ ••••••',
                  style: AppTypography.headlineSm.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(dashboard.totalAssets),
                    style: AppTypography.displayMd.copyWith(color: Colors.white),
                  ),
                ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _ChangePill(
                change: dashboard.monthlyChange,
                percent: dashboard.monthlyChangePercent,
                isPositive: isPositive,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    color: const Color(0xFF70D8C8),
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    isBalanceHidden
                        ? '₺ ••••'
                        : CurrencyFormatter.formatCompact(dashboard.monthlyIncome),
                    style: AppTypography.bodySm.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    Icons.arrow_downward_rounded,
                    color: const Color(0xFFFFB68F),
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    isBalanceHidden
                        ? '₺ ••••'
                        : CurrencyFormatter.formatCompact(dashboard.monthlyExpense),
                    style: AppTypography.bodySm.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (dashboard.creditCardDebt > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Divider(
              color: Colors.white.withValues(alpha: 0.15),
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _BottomStat(
                  label: AppStrings.of(context).netAssets,
                  value: isBalanceHidden
                      ? '₺ ••••'
                      : CurrencyFormatter.format(dashboard.netAssets),
                ),
                const Spacer(),
                _BottomStat(
                  label: AppStrings.of(context).creditCardDebt,
                  value: isBalanceHidden
                      ? '₺ ••••'
                      : CurrencyFormatter.format(dashboard.creditCardDebt),
                  valueColor: AppColors.tertiary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  const _ChangePill({
    required this.change,
    required this.percent,
    required this.isPositive,
  });

  final double change;
  final double percent;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? const Color(0xFF70D8C8) : const Color(0xFFFFB68F),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${percent.toStringAsFixed(1)}%  '
            '${CurrencyFormatter.formatSigned(change)}',
            style: AppTypography.labelMd.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _BottomStat extends StatelessWidget {
  const _BottomStat({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.titleSm.copyWith(
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
