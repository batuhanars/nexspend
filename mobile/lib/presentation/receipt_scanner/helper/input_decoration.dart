import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';

InputDecoration inputDecoration({
  required String hint,
  Widget? prefix,
  String? prefixText,
}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.onSurfaceVariant,
        fontSize: 14,
      ),
      prefixIcon: prefix,
      prefixText: prefixText,
      prefixStyle: prefixText != null
          ? const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            )
          : null,
      filled: true,
      fillColor: AppColors.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
