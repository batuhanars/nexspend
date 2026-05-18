import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/models/statement_model.dart';
import '../../bloc/statements_bloc.dart';
import 'pay_statement_sheet.dart';
import 'statement_status_badge.dart';

class CreditCardStatementsSection extends StatelessWidget {
  const CreditCardStatementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StatementsBloc, StatementsState>(
      listener: (context, state) {
        if (state is StatementsLoaded) {
          if (state.paymentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(AppStrings.of(context).paymentSuccessSnackbar),
              backgroundColor: AppColors.secondary,
            ));
          } else if (state.payError != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.payError!),
              backgroundColor: AppColors.error,
            ));
          }
        }
      },
      builder: (context, state) {
        if (state is StatementsLoading || state is StatementsInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (state is StatementsError) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding),
            child: Text(
              state.message,
              style:
                  AppTypography.bodySm.copyWith(color: AppColors.error),
            ),
          );
        }
        if (state is! StatementsLoaded) return const SizedBox.shrink();

        final r = state.response;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CurrentPeriodCard(period: r.currentPeriod),
            if (r.openStatements.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(text: AppStrings.of(context).openStatementsTitle),
              const SizedBox(height: AppSpacing.md),
              ...r.openStatements.map(
                (s) => _StatementTile(
                  statement: s,
                  onPay: () => _openPaySheet(context, s, state),
                ),
              ),
            ],
            if (r.history.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(
                  text: AppStrings.of(context).statementHistoryTitle),
              const SizedBox(height: AppSpacing.md),
              ...r.history.map(
                (s) => _StatementTile(statement: s, onPay: null),
              ),
            ],
            if (r.openStatements.isEmpty && r.history.isEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding),
                child: Text(
                  AppStrings.of(context).noStatementsYet,
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _openPaySheet(
    BuildContext context,
    StatementModel statement,
    StatementsLoaded state,
  ) {
    final bloc = context.read<StatementsBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: PayStatementSheet(
          statement: statement,
          payableAccounts: state.payableAccounts,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Text(text, style: AppTypography.titleSm),
    );
  }
}

class _CurrentPeriodCard extends StatelessWidget {
  const _CurrentPeriodCard({required this.period});
  final CurrentPeriodModel period;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.currentPeriodTitle, style: AppTypography.titleSm),
                Text(
                  '${DateFormatter.formatMini(period.periodStart, context)} – ${DateFormatter.formatMini(period.periodEnd, context)}',
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              CurrencyFormatter.format(period.spentAmount),
              style: AppTypography.headlineSm
                  .copyWith(color: AppColors.tertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${s.spentThisPeriod} · ${s.txCountLabel(period.transactionCount)}',
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementTile extends StatelessWidget {
  const _StatementTile({required this.statement, required this.onPay});
  final StatementModel statement;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${DateFormatter.formatMini(statement.periodStart, context)} – ${DateFormatter.formatMini(statement.periodEnd, context)}',
                    style: AppTypography.bodyMd
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                StatementStatusBadge(status: statement.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _AmountColumn(
                  label: s.totalAmountShortLabel,
                  amount: statement.totalAmount,
                ),
                _AmountColumn(
                  label: s.minimumPaymentLabel,
                  amount: statement.minimumPayment,
                ),
                _AmountColumn(
                  label: s.remainingLabel,
                  amount: statement.remainingAmount,
                  emphasize: !statement.status.isPaid,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${s.dueDateLabel}: ${DateFormatter.formatMini(statement.dueDate, context)}',
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                if (onPay != null && !statement.status.isPaid)
                  TextButton(
                    onPressed: onPay,
                    child: Text(
                      s.payButton,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final double amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSm
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.format(amount),
            style: AppTypography.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: emphasize
                  ? AppColors.tertiary
                  : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
