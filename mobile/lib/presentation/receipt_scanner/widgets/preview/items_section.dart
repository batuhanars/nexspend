import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/data/models/receipt_model.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/preview/item_row.dart';

class ItemsSection extends StatelessWidget {
  const ItemsSection({super.key, required this.items});
  final List<ReceiptItemModel> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.of(context).productsLabel,
          style: AppTypography.labelSm.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map(
                  (entry) => ItemRow(
                    item: entry.value,
                    isLast: entry.key == items.length - 1,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
