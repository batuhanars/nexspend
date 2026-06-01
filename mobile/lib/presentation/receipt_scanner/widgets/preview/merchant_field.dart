import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
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
    final colors = context.colors;
    return TextField(
      controller: controller,
      style: TextStyle(color: colors.onSurface, fontSize: 14),
      onChanged: (v) => context.read<ReceiptPreviewBloc>().add(
        ReceiptPreviewFieldUpdated(merchantName: v),
      ),
      decoration: inputDecoration(
        hint: AppStrings.of(context).merchantNameHint,
        colors: colors,
        prefix: Icon(
          Icons.storefront_outlined,
          size: 20,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
