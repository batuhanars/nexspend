import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../bloc/transactions_bloc.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.budgetLabel,
    this.selectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onTapInSelection,
  });
  final TransactionModel transaction;
  final String? budgetLabel;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTapInSelection;

  bool get _isManual => transaction.source == TransactionSource.MANUAL;

  static Color _hexColor(String hex, Color fallback) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

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
        : isIncome
            ? colors.income
            : colors.expense;

    final iconData = transaction.category?.icon != null
        ? IconMapper.fromString(transaction.category!.icon)
        : isIncome
            ? Icons.arrow_downward_rounded
            : isTransfer
                ? Icons.swap_horiz_rounded
                : Icons.arrow_upward_rounded;

    final tileBackground = selectionMode && isSelected && _isManual
        ? colors.primary.withValues(alpha: 0.10)
        : Colors.transparent;

    Widget tile = InkWell(
      onTap: () {
        if (selectionMode) {
          if (_isManual) {
            onTapInSelection?.call();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppStrings.of(context).nonManualSelectError),
              backgroundColor: colors.surfaceContainerHighest,
              duration: const Duration(seconds: 2),
            ));
          }
        } else {
          context.push(
            RouteNames.transactionDetail(transaction.id),
            extra: {
              'transaction': transaction,
              'bloc': context.read<TransactionsBloc>(),
            },
          );
        }
      },
      onLongPress: selectionMode ? null : onLongPress,
      child: Container(
        color: tileBackground,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (selectionMode && _isManual)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.20)
                      : colors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? Icons.check_rounded : iconData,
                  color: isSelected ? colors.primary : categoryColor,
                  size: 20,
                ),
              )
            else
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
                        (isTransfer
                            ? AppStrings.of(context).transfer
                            : AppStrings.of(context).transactionFallback),
                    style: AppTypography.bodyMd
                        .copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${transaction.account?.name ?? ''}  •  ${DateFormatter.formatShort(transaction.date, context)}, ${DateFormatter.formatTime(transaction.date)}',
                          style: AppTypography.bodySm.copyWith(
                              color: colors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_sourceIcon(transaction.source) != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _sourceIcon(transaction.source),
                          size: 12,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                  if (budgetLabel != null) ...[
                    const SizedBox(height: 4),
                    _BudgetBadge(label: budgetLabel!),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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

    if (selectionMode) return tile;
    if (transaction.source != TransactionSource.MANUAL) return tile;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: colors.errorContainer,
        child: Icon(Icons.delete_outline_rounded, color: colors.error),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        context
            .read<TransactionsBloc>()
            .add(TransactionDeleteRequested(transaction.id));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.of(context).transactionDeletedSuccess),
          backgroundColor: colors.income,
        ));
      },
      child: tile,
    );
  }

  IconData? _sourceIcon(TransactionSource source) => switch (source) {
        TransactionSource.RECURRING => Icons.repeat_rounded,
        TransactionSource.DEBT_PAYMENT => Icons.money_off_rounded,
        TransactionSource.DEBT_COLLECTION => Icons.attach_money_rounded,
        TransactionSource.SUBSCRIPTION => Icons.schedule_rounded,
        TransactionSource.MANUAL => null,
      };

  Future<bool?> _confirmDelete(BuildContext context) {
    final colors = context.colors;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceContainerHigh,
        title: Text(AppStrings.of(context).deleteTransactionTitle,
            style: AppTypography.titleSm),
        content: Text(
          AppStrings.of(context).deleteTransactionContent,
          style: AppTypography.bodyMd
              .copyWith(color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.of(context).delete,
                style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }
}

class _BudgetBadge extends StatelessWidget {
  const _BudgetBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 10,
            color: colors.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: colors.primary,
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
