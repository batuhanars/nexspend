import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/data/models/account_model.dart';
import 'package:wallet_app/data/models/debt_model.dart';
import 'package:wallet_app/data/repositories/account_repository.dart';
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
  String? _selectedAccountId;
  late final Future<List<AccountModel>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.debt.remainingAmount
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    _accountsFuture = getIt<AccountRepository>().getAccounts();
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
    if (_selectedAccountId == null) return;

    final isLent = widget.debt.type == DebtType.LENT;
    context.read<DebtsBloc>().add(
      DebtPaymentRecorded(
        debtId: widget.debt.id,
        data: {
          'amount': amount,
          'accountId': _selectedAccountId!,
          if (_noteController.text.trim().isNotEmpty)
            'note': _noteController.text.trim(),
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isLent
            ? AppStrings.of(context).debtCollectionSuccess
            : AppStrings.of(context).debtPaymentSuccess),
        backgroundColor: AppColors.secondary,
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
                isLent ? AppStrings.of(context).receivedPaymentTitle : AppStrings.of(context).payDebtTitle,
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
            widget.debt.personName,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            readOnly: true,
            style: AppTypography.headlineSm,
            decoration: InputDecoration(
              labelText: AppStrings.of(context).amountHint,
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
              final accounts =
                  snapshot.data!.where((a) => !a.isArchived).toList();
              if (accounts.isEmpty) {
                return Text(
                  AppStrings.of(context).noAccountsFound,
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
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
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.primary, width: 1.5)
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
          TextField(
            controller: _noteController,
            style: AppTypography.bodyMd,
            decoration: InputDecoration(
              hintText: AppStrings.of(context).noteOptionalHint,
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
            child: Text(isLent ? AppStrings.of(context).collectPaymentBtn : AppStrings.of(context).makePaymentBtn),
          ),
        ],
      ),
    );
  }
}
