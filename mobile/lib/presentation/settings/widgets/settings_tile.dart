import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
    this.showChevron = true,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
      ),
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.onSurfaceVariant,
        size: 22,
      ),
      title: Text(
        label,
        style: AppTypography.bodyMd.copyWith(
          color: labelColor ?? AppColors.onSurface,
        ),
      ),
      trailing: showChevron
          ? Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              size: 20,
            )
          : null,
      onTap: onTap,
    );
  }
}
