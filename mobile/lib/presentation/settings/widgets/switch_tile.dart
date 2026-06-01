import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';

class SwitchTile extends StatelessWidget {
  const SwitchTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
      ),
      leading: Icon(icon, color: context.colors.onSurfaceVariant, size: 22),
      title: Text(label, style: AppTypography.bodyMd),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: context.colors.primary,
        activeTrackColor: context.colors.primary.withValues(alpha: 0.4),
      ),
    );
  }
}
