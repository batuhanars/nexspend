import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/theme/app_palette.dart';

InputDecoration inputDecoration({
  required String hint,
  required AppPalette colors,
  Widget? prefix,
  String? prefixText,
}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: colors.onSurfaceVariant,
        fontSize: 14,
      ),
      prefixIcon: prefix,
      prefixText: prefixText,
      prefixStyle: prefixText != null
          ? TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            )
          : null,
      filled: true,
      fillColor: colors.surfaceContainerHighest,
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
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    );
