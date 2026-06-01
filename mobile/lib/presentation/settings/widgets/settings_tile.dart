import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.labelColor,
    this.iconColor,
    this.showChevron = true,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;
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
        color: iconColor ?? context.colors.onSurfaceVariant,
        size: 22,
      ),
      title: Text(
        label,
        style: AppTypography.bodyMd.copyWith(
          color: labelColor ?? context.colors.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.labelSm.copyWith(
                color: context.colors.onSurfaceVariant,
                letterSpacing: 0,
              ),
            )
          : null,
      trailing: showChevron
          ? Icon(
              Icons.chevron_right_rounded,
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.6),
              size: 20,
            )
          : null,
      onTap: onTap,
    );
  }
}
