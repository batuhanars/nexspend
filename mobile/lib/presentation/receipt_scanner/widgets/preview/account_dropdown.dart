import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/data/models/account_model.dart';
import 'package:wallet_app/navigation/route_names.dart';
import 'package:wallet_app/presentation/receipt_scanner/bloc/receipt_preview_bloc.dart';
import 'package:wallet_app/presentation/receipt_scanner/helper/input_decoration.dart';

class AccountDropdown extends StatelessWidget {
  const AccountDropdown({super.key, required this.state});
  final ReceiptPreviewReady state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hint = state.result.suggestedAccountHint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.accounts.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: state.selectedAccountId,
            dropdownColor: colors.surfaceContainerHigh,
            style: TextStyle(color: colors.onSurface, fontSize: 14),
            decoration: inputDecoration(
              hint: AppStrings.of(context).selectAccountHint,
              colors: colors,
              prefix: Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ),
            items: state.accounts
                .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                .toList(),
            onChanged: (id) => context.read<ReceiptPreviewBloc>().add(
              ReceiptPreviewFieldUpdated(accountId: id),
            ),
          ),
        if (state.unmatchedBankName != null || state.unmatchedCash) ...[
          const SizedBox(height: AppSpacing.sm),
          _AddAccountCta(
            label: state.unmatchedBankName != null
                ? AppStrings.of(context)
                    .receiptDetectedBankAddPrompt(state.unmatchedBankName!)
                : AppStrings.of(context).receiptDetectedCashAddPrompt,
            onTap: () => _openAddAccount(context, hint?.paymentMethod),
          ),
        ],
      ],
    );
  }

  Future<void> _openAddAccount(BuildContext context, String? paymentMethod) async {
    final bloc = context.read<ReceiptPreviewBloc>();
    final result = await GoRouter.of(context).push<AccountModel>(
      RouteNames.addAccount,
      extra: <String, dynamic>{
        if (state.unmatchedBankName != null) 'bankName': state.unmatchedBankName,
        'type': _typeForPaymentMethod(paymentMethod),
      },
    );
    if (result != null) {
      bloc.add(ReceiptPreviewAccountAdded(result));
    }
  }

  AccountType _typeForPaymentMethod(String? paymentMethod) {
    return switch (paymentMethod) {
      'CASH' => AccountType.CASH,
      'CREDIT_CARD' => AccountType.CREDIT_CARD,
      'DEBIT_CARD' => AccountType.BANK,
      // Banka adı tespit edildiyse büyük ihtimalle kart hesabı; default BANK.
      _ => AccountType.BANK,
    };
  }
}

class _AddAccountCta extends StatelessWidget {
  const _AddAccountCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySm.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
