import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '₺',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: color,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 220,
              child: TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  height: 1.0,
                ),
                cursorColor: color,
                cursorWidth: 2,
                cursorHeight: 52,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 56,
                    fontWeight: FontWeight.w300,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
                    height: 1.0,
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0),
                color.withValues(alpha: 0.7),
                color.withValues(alpha: 0),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
