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

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.onViewAll,
  });

  final List<TransactionModel> transactions;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (transactions.isEmpty) return _EmptyTransactions(s: s);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Row(
            children: [
              Text(s.recentTransactions, style: AppTypography.titleSm),
              const Spacer(),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  s.viewAll,
                  style: AppTypography.bodySm.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...transactions.take(5).map(
              (t) => _TransactionTile(transaction: t, s: s),
            ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.s});
  final TransactionModel transaction;
  final AppStrings s;

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
        ? _colorFromHex(transaction.category!.color!)
        : isIncome
            ? AppColors.secondary
            : AppColors.tertiary;

    final iconData = transaction.category?.icon != null
        ? IconMapper.fromString(transaction.category!.icon)
        : isIncome
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: categoryColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ??
                      transaction.category?.localizedName(context) ??
                      s.transactionFallback,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${transaction.account?.name ?? ''}'
                  '  •  ${DateFormatter.formatShort(transaction.date)}, ${DateFormatter.formatTime(transaction.date)}',
                  style: AppTypography.bodySm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : isTransfer ? '' : '-'}'
                '${CurrencyFormatter.format(transaction.amount)}',
                style: AppTypography.bodyMd.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (transaction.source != TransactionSource.MANUAL)
                _SourceBadge(source: transaction.source),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorFromHex(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.onSurfaceVariant;
    }
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final TransactionSource source;

  @override
  Widget build(BuildContext context) {
    final icon = switch (source) {
      TransactionSource.RECURRING => Icons.repeat_rounded,
      TransactionSource.SUBSCRIPTION => Icons.subscriptions_outlined,
      TransactionSource.DEBT_PAYMENT => Icons.handshake_outlined,
      TransactionSource.DEBT_COLLECTION => Icons.handshake_outlined,
      TransactionSource.MANUAL => Icons.edit_outlined,
    };
    return Icon(icon, size: 12, color: AppColors.onSurfaceVariant);
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(s.recentTransactions, style: AppTypography.titleSm),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            s.noTransactionsYet,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(s.addFirstTransaction, style: AppTypography.bodySm),
        ],
      ),
    );
  }
}
