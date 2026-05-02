import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/presentation/receipt_scanner/bloc/receipt_preview_bloc.dart';
import 'package:wallet_app/presentation/receipt_scanner/helper/input_decoration.dart';

class AmountField extends StatelessWidget {
  const AmountField({super.key, required this.controller, required this.state});
  final TextEditingController controller;
  final ReceiptPreviewReady state;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
      onChanged: (v) {
        final amount = double.tryParse(v.replaceAll(',', '.'));
        if (amount != null) {
          context.read<ReceiptPreviewBloc>().add(
            ReceiptPreviewFieldUpdated(amount: amount),
          );
        }
      },
      decoration: inputDecoration(
        hint: '0,00',
        prefix: const Icon(
          Icons.attach_money_rounded,
          size: 20,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
