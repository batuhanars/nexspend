import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/presentation/receipt_scanner/bloc/receipt_preview_bloc.dart';
import 'package:wallet_app/presentation/receipt_scanner/helper/input_decoration.dart';

class MerchantField extends StatelessWidget {
  const MerchantField({
    super.key,
    required this.controller,
    required this.state,
  });
  final TextEditingController controller;
  final ReceiptPreviewReady state;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
      onChanged: (v) => context.read<ReceiptPreviewBloc>().add(
        ReceiptPreviewFieldUpdated(merchantName: v),
      ),
      decoration: inputDecoration(
        hint: AppStrings.of(context).merchantNameHint,
        prefix: const Icon(
          Icons.storefront_outlined,
          size: 20,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
