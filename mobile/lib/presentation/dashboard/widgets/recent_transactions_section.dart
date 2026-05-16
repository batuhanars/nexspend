import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/category_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/family_model.dart';
import '../../../data/models/transaction_model.dart';

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.onViewAll,
    this.personalBudgets = const [],
    this.sharedBudgets = const [],
  });

  final List<TransactionModel> transactions;
  final VoidCallback onViewAll;
  final List<BudgetModel> personalBudgets;
  final List<MySharedBudgetModel> sharedBudgets;

  String? _budgetLabel(TransactionModel tx) {
    if (tx.type != TransactionType.EXPENSE) return null;
    if (tx.sharedBudgetId != null) {
      final match =
          sharedBudgets.where((b) => b.id == tx.sharedBudgetId).toList();
      if (match.isEmpty) return null;
      final b = match.first;
      return b.groupName.isNotEmpty ? '${b.groupName} · ${b.name}' : b.name;
    }
    final catId = tx.category?.id;
    if (catId == null) return null;
    for (final b in personalBudgets) {
      if (!b.isActive) continue;
      if (b.category?.id != catId) continue;
      if (tx.date.isBefore(b.startDate)) continue;
      if (b.endDate != null && tx.date.isAfter(b.endDate!)) continue;
      return b.name;
    }
    return null;
  }

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
              (t) => _TransactionTile(
                transaction: t,
                s: s,
                budgetLabel: _budgetLabel(t),
              ),
            ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.s,
    this.budgetLabel,
  });
  final TransactionModel transaction;
  final AppStrings s;
  final String? budgetLabel;

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
                if (budgetLabel != null) ...[
                  const SizedBox(height: 4),
                  _BudgetBadge(label: budgetLabel!),
                ],
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

class _BudgetBadge extends StatelessWidget {
  const _BudgetBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 10,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.primary,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
