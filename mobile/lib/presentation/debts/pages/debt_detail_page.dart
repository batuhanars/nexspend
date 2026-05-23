import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/utils/currency_formatter.dart';
import 'package:wallet_app/data/models/account_model.dart';
import 'package:wallet_app/data/models/debt_model.dart';
import 'package:wallet_app/data/repositories/account_repository.dart';
import 'package:wallet_app/presentation/debts/bloc/debt_detail_bloc.dart';
import 'package:wallet_app/presentation/debts/widgets/installment_row.dart';
import 'package:wallet_app/presentation/debts/widgets/payment_row.dart';

class DebtDetailPage extends StatelessWidget {
  const DebtDetailPage({super.key, required this.debt});
  final DebtModel debt;

  @override
  Widget build(BuildContext context) {
    context.read<DebtDetailBloc>().add(DebtDetailLoadRequested(debt: debt));
    return const _DebtDetailView();
  }
}

class _DebtDetailView extends StatelessWidget {
  const _DebtDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DebtDetailBloc, DebtDetailState>(
      listener: (context, state) {
        if (state is DebtDetailDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context).debtDeletedSuccess),
              backgroundColor: AppColors.secondary,
            ),
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final debt = state is DebtDetailLoaded
            ? state.debt
            : state is DebtDetailLoading
            ? null
            : (context.read<DebtDetailBloc>().state is DebtDetailLoaded
                  ? (context.read<DebtDetailBloc>().state as DebtDetailLoaded)
                        .debt
                  : null);

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: debt != null
                ? Text(debt.personName, style: AppTypography.headlineSm)
                : null,
            centerTitle: false,
            actions: [
              if (debt != null)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  tooltip: AppStrings.of(context).delete,
                  onPressed: () => _confirmDelete(context, debt),
                ),
            ],
          ),
          body: switch (state) {
            DebtDetailLoading() => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            DebtDetailError(:final message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    message,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.tonal(
                    onPressed: () => context.read<DebtDetailBloc>().add(
                      DebtDetailRefreshRequested(),
                    ),
                    child: Text(AppStrings.of(context).retry),
                  ),
                ],
              ),
            ),
            DebtDetailLoaded(
              :final debt,
              :final installments,
              :final payments,
            ) =>
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => context.read<DebtDetailBloc>().add(
                  DebtDetailRefreshRequested(),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  children: [
                    _HeaderCard(debt: debt),
                    const SizedBox(height: AppSpacing.xl),
                    if (debt.hasInstallments && installments.isNotEmpty) ...[
                      _SectionCard(
                        title: AppStrings.of(context).installmentsSection,
                        subtitle: AppStrings.of(context).installmentsPaid(
                          installments
                              .where((i) => i.status == DebtStatus.PAID)
                              .length
                              .toString(),
                          installments.length.toString(),
                        ),
                        children: installments
                            .map(
                              (i) => InstallmentRow(
                                installment: i,
                                isLent: debt.type == DebtType.LENT,
                                onPay:
                                    i.status != DebtStatus.PAID &&
                                        debt.status != DebtStatus.PAID
                                    ? () => _showInstallmentPayment(
                                        context,
                                        i,
                                        debt,
                                      )
                                    : null,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (payments.isNotEmpty)
                      _SectionCard(
                        title: AppStrings.of(context).paymentHistoryTitle,
                        subtitle: AppStrings.of(
                          context,
                        ).paymentsCount(payments.length),
                        children: payments
                            .map(
                              (p) => PaymentRow(
                                payment: p,
                                isLent: debt.type == DebtType.LENT,
                              ),
                            )
                            .toList(),
                      )
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                          ),
                          child: Text(
                            AppStrings.of(context).noPaymentsYet,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            _ => const SizedBox.shrink(),
          },
          bottomNavigationBar:
              state is DebtDetailLoaded &&
                  state.debt.status != DebtStatus.PAID &&
                  (!state.debt.hasInstallments || state.installments.isEmpty)
              ? Container(
                  color: AppColors.surface,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        AppSpacing.sm,
                        AppSpacing.pagePadding,
                        AppSpacing.lg,
                      ),
                      child: FilledButton(
                        onPressed: () => _showPaymentSheet(context, state.debt),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXl,
                            ),
                          ),
                        ),
                        child: Text(
                          state.debt.type == DebtType.LENT
                              ? AppStrings.of(context).collectPaymentBtn
                              : AppStrings.of(context).makePaymentBtn,
                          style: AppTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, DebtModel debt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(
          AppStrings.of(context).deleteDebtTitle,
          style: AppTypography.titleSm,
        ),
        content: Text(
          '${debt.personName} ile olan borç kaydı silinecek.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppStrings.of(context).delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<DebtDetailBloc>().add(DebtDetailDeleteRequested());
    }
  }

  void _showPaymentSheet(BuildContext context, DebtModel debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<DebtDetailBloc>(),
        child: _DetailPaymentSheet(debt: debt),
      ),
    );
  }

  void _showInstallmentPayment(
    BuildContext context,
    DebtInstallmentModel installment,
    DebtModel debt,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<DebtDetailBloc>(),
        child: _DetailPaymentSheet(debt: debt, installment: installment),
      ),
    );
  }
}

// Payment sheet that dispatches to DebtDetailBloc (not DebtsBloc)
class _DetailPaymentSheet extends StatefulWidget {
  const _DetailPaymentSheet({required this.debt, this.installment});
  final DebtModel debt;
  final DebtInstallmentModel?
  installment; // null = free-form, non-null = specific installment

  @override
  State<_DetailPaymentSheet> createState() => _DetailPaymentSheetState();
}

class _DetailPaymentSheetState extends State<_DetailPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _selectedAccountId;
  late final Future<List<AccountModel>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _accountsFuture = getIt<AccountRepository>().getAccounts();
    if (widget.installment != null) {
      _amountCtrl.text = widget.installment!.remainingAmount
          .toStringAsFixed(2)
          .replaceAll('.', ',');
    } else {
      _amountCtrl.text = widget.debt.remainingAmount
          .toStringAsFixed(2)
          .replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  void _submit() {
    final s = AppStrings.of(context);
    final amountStr = _amountCtrl.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      _showError(s.enterValidAmount);
      return;
    }
    if (_selectedAccountId == null) {
      _showError(s.selectAccount);
      return;
    }

    context.read<DebtDetailBloc>().add(
      DebtDetailPaymentMade({
        'amount': amount,
        'accountId': _selectedAccountId!,
        if (widget.installment != null) 'installmentId': widget.installment!.id,
        if (_noteCtrl.text.trim().isNotEmpty) 'note': _noteCtrl.text.trim(),
      }),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLent = widget.debt.type == DebtType.LENT;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xl,
        AppSpacing.pagePadding,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.installment != null
                    ? AppStrings.of(context).installmentPaymentTitle(
                        widget.installment!.installmentNo,
                      )
                    : (isLent
                          ? AppStrings.of(context).receivedPaymentTitle
                          : AppStrings.of(context).payDebtTitle),
                style: AppTypography.headlineSm,
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.installment != null
                ? AppStrings.of(context).installmentAmountLabel(
                    CurrencyFormatter.format(widget.installment!.amount),
                  )
                : AppStrings.of(context).remainingAmountLabel(
                    CurrencyFormatter.format(widget.debt.remainingAmount),
                  ),
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.lg),
          _inputField(
            _amountCtrl,
            AppStrings.of(context).amountHint,
            Icons.attach_money_rounded,
            numeric: true,
            readOnly: widget.installment != null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.of(context).accountLabel,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FutureBuilder<List<AccountModel>>(
            future: _accountsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 36,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }
              final accounts = snapshot.data!
                  .where((a) => !a.isArchived)
                  .toList();
              if (accounts.isEmpty) {
                return Text(
                  AppStrings.of(context).noAccountsFound,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                );
              }
              if (_selectedAccountId == null) {
                final def = accounts.firstWhere(
                  (a) => a.isDefault,
                  orElse: () => accounts.first,
                );
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => setState(() => _selectedAccountId = def.id),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: accounts.map((a) {
                    final isSelected = _selectedAccountId == a.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAccountId = a.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 1.5)
                              : null,
                        ),
                        child: Text(
                          a.name,
                          style: AppTypography.labelSm.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _inputField(
            _noteCtrl,
            AppStrings.of(context).noteOptionalHint,
            Icons.notes_outlined,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: Text(AppStrings.of(context).save),
          ),
        ],
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool numeric = false,
    bool readOnly = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      readOnly: readOnly,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Header Card ──────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.debt});
  final DebtModel debt;

  @override
  Widget build(BuildContext context) {
    final color = debt.type.color;
    final progress = debt.progress;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  debt.type.label,
                  style: AppTypography.labelSm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: debt.status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  debt.status.label,
                  style: AppTypography.labelSm.copyWith(
                    color: debt.status.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            CurrencyFormatter.format(debt.remainingAmount),
            style: AppTypography.headlineMd.copyWith(color: color),
          ),
          Text(
            AppStrings.of(context).remainingLabel,
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.of(
                  context,
                ).paidLabel(CurrencyFormatter.formatCompact(debt.paidAmount)),
                style: AppTypography.bodySm,
              ),
              Text(
                AppStrings.of(
                  context,
                ).totalLabel(CurrencyFormatter.format(debt.totalAmount)),
                style: AppTypography.bodySm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Text(title, style: AppTypography.titleSm),
              if (subtitle != null)
                Text(subtitle!, style: AppTypography.bodySm),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children
              .expand(
                (w) => [
                  w,
                  const Divider(
                    color: AppColors.surfaceContainerHighest,
                    height: 1,
                  ),
                ],
              )
              .take(children.length * 2 - 1),
        ],
      ),
    );
  }
}
