import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/data/models/debt_model.dart';
import 'package:wallet_app/presentation/debts/bloc/debts_bloc.dart';

class PaymentSheet extends StatefulWidget {
  const PaymentSheet({super.key, required this.debt});
  final DebtModel debt;

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.debt.remainingAmount
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountStr = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;
    context.read<DebtsBloc>().add(
      DebtPaymentRecorded(
        debtId: widget.debt.id,
        data: {
          'amount': amount,
          if (_noteController.text.trim().isNotEmpty)
            'note': _noteController.text.trim(),
        },
      ),
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            widget.debt.personName,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: AppTypography.headlineSm,
            decoration: InputDecoration(
              labelText: 'Tutar (₺)',
              labelStyle: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteController,
            style: AppTypography.bodyMd,
            decoration: InputDecoration(
              hintText: 'Not (opsiyonel)',
              hintStyle: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
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
            child: Text(isLent ? 'Tahsilat Kaydet' : 'Ödeme Kaydet'),
          ),
        ],
      ),
    );
  }
}
