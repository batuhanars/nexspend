import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account_model.dart';
import 'credit_bar.dart';

class AccountHeaderCard extends StatelessWidget {
  const AccountHeaderCard({super.key, required this.account});
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCC = account.type == AccountType.CREDIT_CARD;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: account.cardColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: account.cardColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: account.cardColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(account.iconData, color: account.cardColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: AppTypography.titleSm),
                    Text(
                      account.type.labelOf(context),
                      style: AppTypography.bodySm
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (account.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 12, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.of(context).defaultBadge,
                        style: AppTypography.labelSm.copyWith(
                          color: colors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isCC ? AppStrings.of(context).usedLabel : AppStrings.of(context).balanceLabel,
            style: AppTypography.labelSm
                .copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.format(
              isCC ? account.creditUsed : account.balance,
            ),
            style: AppTypography.displayMd.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isCC && account.creditLimit != null) ...[
            const SizedBox(height: AppSpacing.md),
            CreditBar(account: account),
          ],
        ],
      ),
    );
  }
}
