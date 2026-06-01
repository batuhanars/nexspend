import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account_model.dart';
import 'credit_bar.dart';

class AccountListTile extends StatelessWidget {
  const AccountListTile({super.key, required this.account, required this.onTap});
  final AccountModel account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: account.cardColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(account.iconData, size: 22, color: account.cardColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              account.name,
                              style: AppTypography.titleSm,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (account.isDefault) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const AccountDefaultBadge(),
                          ],
                        ],
                      ),
                      Text(
                        account.type.labelOf(context),
                        style: AppTypography.bodySm
                            .copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(account.balance),
                      style: AppTypography.titleSm.copyWith(
                        color: account.balance >= 0
                            ? colors.onSurface
                            : colors.error,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      account.currency,
                      style: AppTypography.bodySm
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            if (account.type == AccountType.CREDIT_CARD &&
                account.creditLimit != null) ...[
              const SizedBox(height: AppSpacing.md),
              CreditBar(account: account, compact: true),
            ],
          ],
        ),
      ),
    );
  }
}

class AccountDefaultBadge extends StatelessWidget {
  const AccountDefaultBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        AppStrings.of(context).defaultBadge,
        style: AppTypography.labelSm
            .copyWith(color: colors.primary, fontSize: 10),
      ),
    );
  }
}
