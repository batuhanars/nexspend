import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/category_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/transaction_model.dart';
import '../../../navigation/route_names.dart';

class AccountTransactionsSection extends StatelessWidget {
  const AccountTransactionsSection({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
    this.onTransactionChanged,
  });
  final List<TransactionModel> transactions;
  final VoidCallback onAddTransaction;
  final VoidCallback? onTransactionChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                    color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppStrings.of(context).noTransactions,
                    style: AppTypography.bodyMd
                        .copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: onAddTransaction,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(AppStrings.of(context).addTransactionBtn),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.surface,
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
              .map((t) => AccountTransactionTile(
                    transaction: t,
                    onChanged: onTransactionChanged,
                  )),
      ],
    );
  }
}

class AccountTransactionTile extends StatelessWidget {
  const AccountTransactionTile({
    super.key,
    required this.transaction,
    this.onChanged,
  });
  final TransactionModel transaction;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isIncome = transaction.type == TransactionType.INCOME;
    final isTransfer = transaction.type == TransactionType.TRANSFER;
    final amountColor = isTransfer
        ? colors.onSurfaceVariant
        : isIncome
            ? colors.income
            : colors.expense;

    final categoryColor = transaction.category?.color != null
        ? _hexColor(transaction.category!.color!, colors.onSurfaceVariant)
        : amountColor;

    final iconData = transaction.category?.icon != null
        ? IconMapper.fromString(transaction.category!.icon)
        : isIncome
            ? Icons.arrow_downward_rounded
            : isTransfer
                ? Icons.swap_horiz_rounded
                : Icons.arrow_upward_rounded;

    return InkWell(
      onTap: () async {
        final changed = await context.push<bool>(
          RouteNames.transactionDetail(transaction.id),
          extra: {'transaction': transaction},
        );
        if (changed == true && context.mounted) {
          onChanged?.call();
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
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
                        (isTransfer
                            ? AppStrings.of(context).transfer
                            : AppStrings.of(context).transactionFallback),
                    style: AppTypography.bodyMd
                        .copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateFormatter.formatShort(transaction.date, context),
                    style: AppTypography.bodySm
                        .copyWith(color: colors.onSurfaceVariant),
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
      ),
    );
  }

  Color _hexColor(String hex, Color fallback) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}
