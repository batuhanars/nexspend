import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/category_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/transaction_model.dart';
import '../bloc/transactions_bloc.dart';

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key, required this.transaction});
  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
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

    final desc = transaction.description;
    final title = (desc != null && desc.isNotEmpty)
        ? desc
        : transaction.category?.localizedName(context) ??
            (isTransfer ? s.transfer : s.transactionFallback);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(s.transactionDetailTitle, style: AppTypography.titleSm),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () => _confirmDelete(context, s),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.sm,
          AppSpacing.pagePadding,
          AppSpacing.xxxl,
        ),
        child: _ReceiptCard(
          transaction: transaction,
          amountColor: amountColor,
          categoryColor: categoryColor,
          iconData: iconData,
          title: title,
          isIncome: isIncome,
          isTransfer: isTransfer,
          s: s,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppStrings s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(s.deleteTransactionTitle, style: AppTypography.titleSm),
        content: Text(
          s.deleteTransactionContent,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context
          .read<TransactionsBloc>()
          .add(TransactionDeleteRequested(transaction.id));
      context.pop(true);
    }
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.onSurfaceVariant;
    }
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.transaction,
    required this.amountColor,
    required this.categoryColor,
    required this.iconData,
    required this.title,
    required this.isIncome,
    required this.isTransfer,
    required this.s,
  });

  final TransactionModel transaction;
  final Color amountColor;
  final Color categoryColor;
  final IconData iconData;
  final String title;
  final bool isIncome;
  final bool isTransfer;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final amountText =
        '${isIncome ? '+' : isTransfer ? '' : '-'}${CurrencyFormatter.format(transaction.amount)}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          // ── Header section ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg,
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: categoryColor, size: 28),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.titleSm,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                _TypeBadge(
                  label: isTransfer ? s.transfer : isIncome ? s.income : s.expense,
                  color: amountColor,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  amountText,
                  style: AppTypography.displayLg.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // ── Perforation ────────────────────────────────────────────
          const _PerforationLine(),
          // ── Details section ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl,
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: s.dateLabel,
                  value: DateFormatter.formatLong(transaction.date),
                ),
                _DetailRow(
                  label: s.timeLabel,
                  value: DateFormatter.formatTime(transaction.date),
                ),
                if (transaction.account != null)
                  _DetailRow(
                    label: s.accountLabel,
                    value: transaction.account!.name,
                  ),
                if (transaction.category != null)
                  _DetailRow(
                    label: s.categoryLabel,
                    value: transaction.category!.localizedName(context),
                  ),
                if (transaction.source != TransactionSource.MANUAL)
                  _DetailRow(
                    label: s.sourceLabel,
                    value: _sourceLabel(transaction.source),
                  ),
                if (transaction.description != null &&
                    transaction.description!.isNotEmpty)
                  _DetailRow(
                    label: s.descriptionLabel,
                    value: transaction.description!,
                  ),
                const SizedBox(height: AppSpacing.md),
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  thickness: 1,
                  height: 1,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${s.transactionIdLabel}: ',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        transaction.id,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant
                              .withValues(alpha: 0.5),
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sourceLabel(TransactionSource source) => switch (source) {
        TransactionSource.RECURRING => s.sourceRecurring,
        TransactionSource.DEBT_PAYMENT => s.sourceDebtPayment,
        TransactionSource.DEBT_COLLECTION => s.sourceDebtCollection,
        TransactionSource.SUBSCRIPTION => s.sourceSubscription,
        TransactionSource.MANUAL => s.sourceManual,
      };
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.labelSm.copyWith(
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PerforationLine extends StatelessWidget {
  const _PerforationLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: _DashedLinePainter(),
              child: const SizedBox.expand(),
            ),
          ),
          Container(
            width: 10,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashGap = 4.0;
    final paint = Paint()
      ..color = AppColors.surfaceContainerHighest
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => false;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
