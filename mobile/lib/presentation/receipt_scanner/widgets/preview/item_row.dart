import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/utils/currency_formatter.dart';
import 'package:wallet_app/data/models/receipt_model.dart';

class ItemRow extends StatelessWidget {
  const ItemRow({super.key, required this.item, required this.isLast});
  final ReceiptItemModel item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (item.quantity != null)
                      Text(
                        '× ${item.quantity!.toStringAsFixed(item.quantity! % 1 == 0 ? 0 : 2)}',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(item.totalPrice),
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
            color: AppColors.surfaceContainerHighest,
          ),
      ],
    );
  }
}
