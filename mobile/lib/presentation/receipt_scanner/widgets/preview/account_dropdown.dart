import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/presentation/receipt_scanner/bloc/receipt_preview_bloc.dart';
import 'package:wallet_app/presentation/receipt_scanner/helper/input_decoration.dart';

class AccountDropdown extends StatelessWidget {
  const AccountDropdown({super.key, required this.state});
  final ReceiptPreviewReady state;

  @override
  Widget build(BuildContext context) {
    if (state.accounts.isEmpty) return const SizedBox.shrink();
    return DropdownButtonFormField<String>(
      initialValue: state.selectedAccountId,
      dropdownColor: AppColors.surfaceContainerHigh,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
      decoration: inputDecoration(
        hint: AppStrings.of(context).selectAccountHint,
        prefix: const Icon(
          Icons.account_balance_wallet_outlined,
          size: 20,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      items: state.accounts
          .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
          .toList(),
      onChanged: (id) => context.read<ReceiptPreviewBloc>().add(
        ReceiptPreviewFieldUpdated(accountId: id),
      ),
    );
  }
}
