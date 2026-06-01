import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/app_palette.dart';

import '../../../../core/constants/app_spacing.dart';

class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.ctrl,
    required this.hint,
    required this.obscure,
    required this.onToggle,
  });
  final TextEditingController ctrl;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: context.colors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: context.colors.onSurfaceVariant,
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          size: 20,
          color: context.colors.onSurfaceVariant,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        filled: true,
        fillColor: context.colors.surfaceContainerHighest,
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
          borderSide: const BorderSide(color: context.colors.primary, width: 1.5),
        ),
      ),
    );
  }
}
