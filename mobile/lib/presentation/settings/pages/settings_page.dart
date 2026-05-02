import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/data/repositories/auth_repository.dart';
import 'package:wallet_app/presentation/settings/widgets/change_password_sheet.dart';
import 'package:wallet_app/presentation/settings/widgets/profile_card.dart';
import 'package:wallet_app/presentation/settings/widgets/section_header.dart';
import 'package:wallet_app/presentation/settings/widgets/settings_tile.dart';
import 'package:wallet_app/presentation/settings/widgets/switch_tile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../navigation/route_names.dart';
import '../bloc/settings_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SettingsBloc(userRepository: getIt<UserRepository>())
            ..add(const SettingsLoadRequested()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
        if (state is SettingsLoaded && state.successMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.successMessage!)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Ayarlar', style: AppTypography.headlineSm),
          centerTitle: false,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading || state is SettingsInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state is SettingsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.tonal(
                      onPressed: () => context.read<SettingsBloc>().add(
                        const SettingsLoadRequested(),
                      ),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              );
            }

            final user = state is SettingsLoaded
                ? state.user
                : (state as SettingsSaving).user;
            final isSaving = state is SettingsSaving;

            return ListView(
              children: [
                const SizedBox(height: AppSpacing.lg),
                // Profil kartı
                ProfileCard(
                  user: user,
                  onEditTap: () => context.push(RouteNames.editProfile),
                  isSaving: isSaving,
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader('Hesap'),
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Profili Düzenle',
                  onTap: () => context.push(RouteNames.editProfile),
                ),
                SettingsTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Hesaplarım',
                  onTap: () => context.push(RouteNames.accounts),
                ),
                SettingsTile(
                  icon: Icons.archive_outlined,
                  label: 'Arşivlenmiş Hesaplar',
                  onTap: () => context.push(RouteNames.archivedAccounts),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader('Tercihler'),
                SwitchTile(
                  icon: Icons.notifications_outlined,
                  label: 'Bildirimler',
                  value: user.notificationsEnabled,
                  onChanged: isSaving
                      ? null
                      : (v) => context.read<SettingsBloc>().add(
                          SettingsToggleChanged(
                            field: 'notifications',
                            value: v,
                          ),
                        ),
                ),
                SwitchTile(
                  icon: Icons.fingerprint_rounded,
                  label: 'Biyometrik Giriş',
                  value: user.biometricEnabled,
                  onChanged: isSaving
                      ? null
                      : (v) => context.read<SettingsBloc>().add(
                          SettingsToggleChanged(field: 'biometric', value: v),
                        ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader('Güvenlik'),
                if (user.hasPassword)
                  SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Şifre Değiştir',
                    onTap: () => _showChangePasswordSheet(context),
                  ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader('Oturum'),
                SettingsTile(
                  icon: Icons.logout_rounded,
                  label: 'Çıkış Yap',
                  labelColor: AppColors.error,
                  iconColor: AppColors.error,
                  showChevron: false,
                  onTap: () => _confirmLogout(context),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: const ChangePasswordSheet(),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Çıkış Yap', style: AppTypography.titleSm),
        content: Text(
          'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        await getIt<AuthRepository>().logout();
        if (context.mounted) context.go(RouteNames.login);
      }
    });
  }
}
