import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_palette.dart';

class TransactionTitleField extends StatelessWidget {
  const TransactionTitleField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => _transactionInputField(
        context: context,
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
        context: context,
        controller: controller,
        hint: AppStrings.of(context).noteOptional,
        icon: Icons.notes_outlined,
        maxLines: 2,
        action: TextInputAction.done,
      );
}

Widget _transactionInputField({
  required BuildContext context,
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  required int maxLines,
  required TextInputAction action,
}) {
  final colors = context.colors;
  return TextField(
    controller: controller,
    maxLines: maxLines,
    textInputAction: action,
    style: TextStyle(color: colors.onSurface, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: maxLines > 1 ? 20 : 0),
        child: Icon(icon, size: 20, color: colors.onSurfaceVariant),
      ),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
    ),
  );
}
