import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/utils/currency_formatter.dart';
import 'package:wallet_app/data/models/debt_model.dart';
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
    return BlocBuilder<DebtDetailBloc, DebtDetailState>(
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
          ),
          body: switch (state) {
            DebtDetailLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            DebtDetailError(:final message) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(message,
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.tonal(
                      onPressed: () => context
                          .read<DebtDetailBloc>()
                          .add(DebtDetailRefreshRequested()),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            DebtDetailLoaded(:final debt, :final installments, :final payments) =>
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => context
                    .read<DebtDetailBloc>()
                    .add(DebtDetailRefreshRequested()),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  children: [
                    _HeaderCard(debt: debt),
                    const SizedBox(height: AppSpacing.xl),
                    if (debt.hasInstallments && installments.isNotEmpty) ...[
                      _SectionCard(
                        title: 'Taksitler',
                        subtitle: '${installments.where((i) => i.status == DebtStatus.PAID).length}/${installments.length} ödendi',
                        children: installments
                            .map((i) => InstallmentRow(installment: i))
                            .toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (payments.isNotEmpty)
                      _SectionCard(
                        title: 'Ödeme Geçmişi',
                        subtitle: '${payments.length} işlem',
                        children: payments
                            .map((p) => PaymentRow(
                                  payment: p,
                                  isLent: debt.type == DebtType.LENT,
                                ))
                            .toList(),
                      )
                    else if (!debt.hasInstallments)
                      Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                          child: Text(
                            'Henüz ödeme yapılmadı.',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            _ => const SizedBox.shrink(),
          },
          floatingActionButton: state is DebtDetailLoaded &&
                  state.debt.status != DebtStatus.PAID
              ? FloatingActionButton.extended(
                  onPressed: () => _showPaymentSheet(context, state.debt),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  label: Text(
                    state.debt.type == DebtType.LENT
                        ? 'Ödeme Aldım'
                        : 'Ödeme Yap',
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  icon: const Icon(Icons.payment_rounded),
                )
              : null,
        );
      },
    );
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
}

// Payment sheet that dispatches to DebtDetailBloc (not DebtsBloc)
class _DetailPaymentSheet extends StatefulWidget {
  const _DetailPaymentSheet({required this.debt});
  final DebtModel debt;

  @override
  State<_DetailPaymentSheet> createState() => _DetailPaymentSheetState();
}

class _DetailPaymentSheetState extends State<_DetailPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final amountStr = _amountCtrl.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    context.read<DebtDetailBloc>().add(DebtDetailPaymentMade({
      'amount': amount,
      if (_noteCtrl.text.trim().isNotEmpty) 'note': _noteCtrl.text.trim(),
    }));
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
                isLent ? 'Ödeme Aldım' : 'Ödeme Yap',
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
            'Kalan: ${CurrencyFormatter.format(widget.debt.remainingAmount)}',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.lg),
          _inputField(_amountCtrl, 'Tutar (₺)', Icons.attach_money_rounded,
              numeric: true),
          const SizedBox(height: AppSpacing.md),
          _inputField(_noteCtrl, 'Not (opsiyonel)', Icons.notes_outlined),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: const Text('Kaydet'),
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
  }) {
    return TextField(
      controller: ctrl,
      keyboardType:
          numeric ? const TextInputType.numberWithOptions(decimal: true) : null,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.onSurfaceVariant, fontSize: 14),
        prefixIcon:
            Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
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
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  debt.type.label,
                  style: AppTypography.labelSm
                      .copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      debt.status.color.withValues(alpha: 0.12),
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
            'Kalan tutar',
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
                '${CurrencyFormatter.formatCompact(debt.paidAmount)} ödendi',
                style: AppTypography.bodySm,
              ),
              Text(
                'Toplam: ${CurrencyFormatter.format(debt.totalAmount)}',
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
              .expand((w) => [w, const Divider(color: AppColors.surfaceContainerHighest, height: 1)])
              .take(children.length * 2 - 1),
        ],
      ),
    );
  }
}
