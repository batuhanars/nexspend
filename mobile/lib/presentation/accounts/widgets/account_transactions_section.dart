import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/category_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/transaction_model.dart';

class AccountTransactionsSection extends StatelessWidget {
  const AccountTransactionsSection({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
  });
  final List<TransactionModel> transactions;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Text(AppStrings.of(context).transactionHistory, style: AppTypography.titleSm),
        ),
        const SizedBox(height: AppSpacing.md),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppStrings.of(context).noTransactions,
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: onAddTransaction,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(AppStrings.of(context).addTransactionBtn),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...transactions
              .map((t) => AccountTransactionTile(transaction: t)),
      ],
    );
  }
}

class AccountTransactionTile extends StatelessWidget {
  const AccountTransactionTile({super.key, required this.transaction});
  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.INCOME;
    final isTransfer = transaction.type == TransactionType.TRANSFER;
    final amountColor = isTransfer
        ? AppColors.onSurfaceVariant
        : isIncome
            ? AppColors.secondary
            : AppColors.tertiary;

    final categoryColor = transaction.category?.color != null
        ? _hexColor(transaction.category!.color!)
        : amountColor;

    final iconData = transaction.category?.icon != null
        ? IconMapper.fromString(transaction.category!.icon)
        : isIncome
            ? Icons.arrow_downward_rounded
            : isTransfer
                ? Icons.swap_horiz_rounded
                : Icons.arrow_upward_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: categoryColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ??
                      transaction.category?.localizedName(context) ??
                      (isTransfer ? AppStrings.of(context).transfer : AppStrings.of(context).transactionFallback),
                  style: AppTypography.bodyMd
                      .copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormatter.formatShort(transaction.date, context),
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : isTransfer ? '' : '-'}${CurrencyFormatter.format(transaction.amount)}',
            style: AppTypography.bodyMd.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.onSurfaceVariant;
    }
  }
}
