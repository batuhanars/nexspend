import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class TransactionTitleField extends StatelessWidget {
  const TransactionTitleField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => _transactionInputField(
        controller: controller,
        hint: AppStrings.of(context).descriptionOptional,
        icon: Icons.edit_outlined,
        maxLines: 1,
        action: TextInputAction.next,
      );
}

class TransactionNoteField extends StatelessWidget {
  const TransactionNoteField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => _transactionInputField(
        controller: controller,
        hint: AppStrings.of(context).noteOptional,
        icon: Icons.notes_outlined,
        maxLines: 2,
        action: TextInputAction.done,
      );
}

Widget _transactionInputField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  required int maxLines,
  required TextInputAction action,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    textInputAction: action,
    style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: maxLines > 1 ? 20 : 0),
        child: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
      ),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
    ),
  );
}
