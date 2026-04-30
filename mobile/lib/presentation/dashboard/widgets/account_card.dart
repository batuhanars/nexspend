import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account_model.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    required this.isBalanceHidden,
    this.onTap,
  });

  final AccountModel account;
  final bool isBalanceHidden;
  final VoidCallback? onTap;

  static const double cardWidth = 200.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AccountIcon(account: account),
                const Spacer(),
                if (account.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      'Varsayılan',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.primary,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              account.name,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            isBalanceHidden
                ? Text(
                    '₺ ••••',
                    style: AppTypography.titleSm.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Text(
                    CurrencyFormatter.format(account.balance),
                    style: AppTypography.titleSm.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            if (account.type == AccountType.CREDIT_CARD &&
                account.creditLimit != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _CreditLimitBar(account: account),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountIcon extends StatelessWidget {
  const _AccountIcon({required this.account});
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: account.cardColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(account.iconData, color: account.cardColor, size: 20),
    );
  }
}

class _CreditLimitBar extends StatelessWidget {
  const _CreditLimitBar({required this.account});
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final percent = account.creditUsagePercent;
    final barColor = percent > 0.8
        ? AppColors.error
        : percent > 0.6
            ? AppColors.warning
            : AppColors.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: AppColors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${CurrencyFormatter.formatCompact(account.creditUsed)} / '
          '${CurrencyFormatter.formatCompact(account.creditLimit!)}',
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
