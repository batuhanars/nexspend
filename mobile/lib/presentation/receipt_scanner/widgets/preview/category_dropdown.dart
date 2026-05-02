import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/presentation/receipt_scanner/bloc/receipt_preview_bloc.dart';
import 'package:wallet_app/presentation/receipt_scanner/helper/input_decoration.dart';

class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({super.key, required this.state});
  final ReceiptPreviewReady state;

  @override
  Widget build(BuildContext context) {
    if (state.categories.isEmpty) {
      return const SizedBox.shrink();
    }
    return DropdownButtonFormField<String>(
      initialValue: state.selectedCategoryId,
      dropdownColor: AppColors.surfaceContainerHigh,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
      decoration: inputDecoration(
        hint: 'Kategori seç',
        prefix: const Icon(
          Icons.label_outline,
          size: 20,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      items: state.categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (id) => context.read<ReceiptPreviewBloc>().add(
        ReceiptPreviewFieldUpdated(categoryId: id),
      ),
    );
  }
}
