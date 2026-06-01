import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/core/utils/currency_formatter.dart';
import 'package:wallet_app/data/models/debt_model.dart';
import 'package:wallet_app/navigation/route_names.dart';
import 'package:wallet_app/presentation/debts/bloc/debts_bloc.dart';
import 'package:wallet_app/presentation/debts/widgets/payment_sheet.dart';

Color _debtTypeColor(DebtType type, AppPalette colors) =>
    type == DebtType.LENT ? colors.income : colors.expense;

Color _debtStatusColor(DebtStatus status, AppPalette colors) =>
    switch (status) {
      DebtStatus.PAID => colors.success,
      DebtStatus.OVERDUE => colors.danger,
      _ => colors.warning,
    };

class DebtCard extends StatelessWidget {
  const DebtCard({super.key, required this.debt});
  final DebtModel debt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLent = debt.type == DebtType.LENT;
    final color = _debtTypeColor(debt.type, colors);

    return Dismissible(
      key: ValueKey(debt.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: colors.errorContainer,
        child: Icon(Icons.delete_outline_rounded, color: colors.error),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        context.read<DebtsBloc>().add(DebtDeleteRequested(debt.id));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.of(context).debtDeletedSuccess),
          backgroundColor: colors.secondary,
        ));
      },
      child: GestureDetector(
        onTap: () async {
          final bloc = context.read<DebtsBloc>();
          await context.push(RouteNames.debtDetail(debt.id), extra: debt);
          if (context.mounted) bloc.add(const DebtsRefreshRequested());
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.xs,
          ),
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(debt.type.icon, size: 18, color: color),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.personName,
                            style: AppTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (debt.description != null)
                            Text(
                              debt.description!,
                              style: AppTypography.bodySm.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(debt.remainingAmount),
                          style: AppTypography.titleSm.copyWith(color: color),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _debtStatusColor(debt.status, colors).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Text(
                            debt.status.label,
                            style: AppTypography.labelSm.copyWith(
                              color: _debtStatusColor(debt.status, colors),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: LinearProgressIndicator(
                    value: debt.progress,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.of(context).paidLabel(CurrencyFormatter.formatCompact(debt.paidAmount)),
                      style: AppTypography.bodySm.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      children: [
                        if (debt.hasInstallments)
                          Container(
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 10,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  AppStrings.of(context).installment,
                                  style: AppTypography.labelSm.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (debt.dueDate != null)
                          Text(
                            _dueDateLabel(debt.dueDate!, context),
                            style: AppTypography.bodySm.copyWith(
                              color: _dueDateColor(debt.dueDate!, colors),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (debt.status != DebtStatus.PAID) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: debt.hasInstallments
                          ? () async {
                              final bloc = context.read<DebtsBloc>();
                              await context.push(
                                RouteNames.debtDetail(debt.id),
                                extra: debt,
                              );
                              if (context.mounted) {
                                bloc.add(const DebtsRefreshRequested());
                              }
                            }
                          : () => _showPaymentSheet(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: color, width: 1.5),
                        foregroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      child: Text(
                        debt.hasInstallments
                            ? AppStrings.of(context).viewInstallmentsBtn
                            : (isLent ? AppStrings.of(context).receivedPaymentTitle : AppStrings.of(context).makePaymentBtn),
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dueDateLabel(DateTime due, BuildContext context) {
    final s = AppStrings.of(context);
    final diff = due.difference(DateTime.now()).inDays;
    if (diff < 0) return s.dueDatePassed;
    if (diff == 0) return s.dueDateToday;
    if (diff == 1) return s.dueDateTomorrow;
    return '${due.day}.${due.month.toString().padLeft(2, '0')}.${due.year}';
  }

  Color _dueDateColor(DateTime due, AppPalette colors) {
    final diff = due.difference(DateTime.now()).inDays;
    if (diff < 0) return colors.error;
    if (diff <= 3) return colors.warning;
    return colors.onSurfaceVariant;
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.surfaceContainerHigh,
          title: Text(AppStrings.of(context).deleteDebtTitle, style: AppTypography.titleSm),
          content: Text(
            '${debt.personName} ile olan borç kaydı silinecek.',
            style: AppTypography.bodyMd.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppStrings.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppStrings.of(context).delete, style: TextStyle(color: colors.error)),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<DebtsBloc>(),
        child: PaymentSheet(debt: debt),
      ),
    );
  }
}
