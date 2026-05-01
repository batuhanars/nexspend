import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../navigation/route_names.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          _SectionHeader('Hesap'),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            label: 'Profili Düzenle',
            onTap: () => context.push(RouteNames.editProfile),
          ),
          _SettingsTile(
            icon: Icons.archive_outlined,
            label: 'Arşivlenmiş Hesaplar',
            onTap: () => context.push(RouteNames.archivedAccounts),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader('Oturum'),
          _SettingsTile(
            icon: Icons.logout_rounded,
            label: 'Çıkış Yap',
            labelColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  title: Text('Çıkış Yap', style: AppTypography.titleSm),
                  content: Text(
                    'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        'Çıkış Yap',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await getIt<AuthRepository>().logout();
                if (context.mounted) context.go(RouteNames.login);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xs,
        AppSpacing.pagePadding,
        AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSm.copyWith(
          color: AppColors.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

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
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
