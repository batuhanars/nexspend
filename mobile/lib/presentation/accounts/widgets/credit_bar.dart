import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account_model.dart';

class CreditBar extends StatelessWidget {
  const CreditBar({super.key, required this.account, this.compact = false});
  final AccountModel account;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = account.creditUsagePercent;
    final barColor = pct > 0.8
        ? colors.error
        : compact
            ? (pct > 0.5 ? colors.expense : colors.income)
            : (pct > 0.6 ? colors.warning : colors.income);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.of(context).usedAmount(CurrencyFormatter.format(account.creditUsed)),
                style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
              ),
              Text(
                AppStrings.of(context).limitAmount(CurrencyFormatter.format(account.creditLimit!)),
                style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.of(context).usedSlashLimit,
              style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
            ),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: AppTypography.labelSm.copyWith(color: barColor),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              CurrencyFormatter.format(account.creditUsed),
              style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
            ),
            Text(
              CurrencyFormatter.format(account.creditLimit!),
              style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}
