import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/core/utils/category_extensions.dart';
import 'package:wallet_app/presentation/receipt_scanner/bloc/receipt_preview_bloc.dart';
import 'package:wallet_app/presentation/receipt_scanner/helper/input_decoration.dart';

class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({super.key, required this.state});
  final ReceiptPreviewReady state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (state.categories.isEmpty) {
      return const SizedBox.shrink();
    }
    return DropdownButtonFormField<String>(
      initialValue: state.selectedCategoryId,
      dropdownColor: colors.surfaceContainerHigh,
      style: TextStyle(color: colors.onSurface, fontSize: 14),
      decoration: inputDecoration(
        hint: AppStrings.of(context).selectCategoryHint,
        colors: colors,
        prefix: Icon(Icons.label_outline, size: 20, color: colors.onSurfaceVariant),
      ),
      items: state.categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.localizedName(context))))
          .toList(),
      onChanged: (id) => context.read<ReceiptPreviewBloc>().add(
        ReceiptPreviewFieldUpdated(categoryId: id),
      ),
    );
  }
}
