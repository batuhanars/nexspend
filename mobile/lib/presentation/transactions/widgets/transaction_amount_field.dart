import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class TransactionAmountField extends StatelessWidget {
  const TransactionAmountField({
    super.key,
    required this.controller,
    required this.type,
  });
  final TextEditingController controller;
  final String type;

  @override
  Widget build(BuildContext context) {
    final color = type == 'INCOME'
        ? AppColors.secondary
        : type == 'TRANSFER'
            ? AppColors.primary
            : AppColors.tertiary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('₺', style: AppTypography.displayLg.copyWith(color: color)),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 180,
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            autofocus: true,
            textAlign: TextAlign.left,
            style: AppTypography.displayLg.copyWith(color: color),
            cursorColor: color,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0',
              hintStyle: AppTypography.displayLg.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
