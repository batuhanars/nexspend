import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/storage/secure_storage.dart';
import 'package:wallet_app/core/utils/locale_notifier.dart';
import 'package:wallet_app/core/utils/theme_notifier.dart';
import 'package:wallet_app/data/models/user_model.dart';
import 'package:wallet_app/data/repositories/auth_repository.dart';
import 'package:wallet_app/presentation/settings/widgets/change_password_sheet.dart';
import 'package:wallet_app/presentation/settings/widgets/profile_card.dart';
import 'package:wallet_app/presentation/settings/widgets/section_header.dart';
import 'package:wallet_app/presentation/settings/widgets/settings_tile.dart';
import 'package:wallet_app/presentation/settings/widgets/switch_tile.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../navigation/route_names.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/reset_data_sheet.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsBloc(
            userRepository: getIt<UserRepository>(),
            storage: getIt<SecureStorage>(),
          )..add(const SettingsLoadRequested()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  static const _languages = [
    ('tr', 'Türkçe'),
    ('en', 'English'),
  ];

  static final _themes = [
    (ThemeMode.light, 'light'),
    (ThemeMode.dark, 'dark'),
    (ThemeMode.system, 'system'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: context.colors.error,
            ),
          );
        }
        if (state is SettingsLoaded && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
        }
        if (state is SettingsResetSuccess) {
          final messenger = ScaffoldMessenger.of(context);
          final s = AppStrings.of(context);
          messenger.showSnackBar(
            SnackBar(content: Text(s.resetSuccessMessage)),
          );
          context.go(RouteNames.home);
        }
        if (state is SettingsResetFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: context.colors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.settings, style: AppTypography.headlineSm),
          centerTitle: false,
          backgroundColor: context.colors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading ||
                state is SettingsInitial ||
                state is SettingsResetSuccess) {
              return const Center(
                child: CircularProgressIndicator(color: context.colors.primary),
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
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.tonal(
                      onPressed: () => context.read<SettingsBloc>().add(
                        const SettingsLoadRequested(),
                      ),
                      child: Text(s.retry),
                    ),
                  ],
                ),
              );
            }

            final user = state is SettingsLoaded
                ? state.user
                : state is SettingsSaving
                    ? state.user
                    : state is SettingsResetting
                        ? state.user
                        : (state as SettingsResetFailure).user;
            final isSaving = state is SettingsSaving;
            final isResetting = state is SettingsResetting;

            Future<void> openEditProfile() async {
              await context.push(RouteNames.editProfile);
              if (context.mounted) {
                context
                    .read<SettingsBloc>()
                    .add(const SettingsLoadRequested());
              }
            }

            return ListView(
              children: [
                const SizedBox(height: AppSpacing.lg),
                ProfileCard(
                  user: user,
                  onEditTap: openEditProfile,
                  isSaving: isSaving,
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(s.sectionAccount),
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  label: s.editProfile,
                  onTap: openEditProfile,
                ),
                SettingsTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: s.myAccounts,
                  onTap: () => context.push(RouteNames.accounts),
                ),
                SettingsTile(
                  icon: Icons.archive_outlined,
                  label: s.archivedAccounts,
                  onTap: () => context.push(RouteNames.archivedAccounts),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(s.sectionPreferences),
                SwitchTile(
                  icon: Icons.notifications_outlined,
                  label: s.notifications,
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
                  label: s.biometricLogin,
                  value: user.biometricEnabled,
                  onChanged: isSaving
                      ? null
                      : (v) => context.read<SettingsBloc>().add(
                          SettingsToggleChanged(field: 'biometric', value: v),
                        ),
                ),
                SettingsTile(
                  icon: Icons.translate_rounded,
                  label: s.language,
                  subtitle: _languageSubtitle(user.language),
                  onTap: () => _showLanguagePicker(context, s, user),
                ),
                SettingsTile(
                  icon: Icons.palette_outlined,
                  label: s.theme,
                  subtitle: _themeSubtitle(context),
                  onTap: () => _showThemePicker(context, s),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(s.familyGroupsSection),
                SettingsTile(
                  icon: Icons.group_outlined,
                  label: s.familyBudgetTitle,
                  onTap: () => context.push(RouteNames.family),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(s.sectionTools),
                SettingsTile(
                  icon: Icons.receipt_long_outlined,
                  label: s.receiptHistory,
                  onTap: () => context.push(RouteNames.receiptHistory),
                ),
                if (!user.isGoogleLinked) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(s.sectionSecurity),
                  if (user.hasPassword)
                    SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      label: s.changePassword,
                      onTap: () => _showChangePasswordSheet(context),
                    ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(s.sectionLegal),
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  label: s.privacyPolicyTitle,
                  onTap: () => context.push(RouteNames.privacyPolicy),
                ),
                SettingsTile(
                  icon: Icons.description_outlined,
                  label: s.termsOfServiceTitle,
                  onTap: () => context.push(RouteNames.termsOfService),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(s.sectionSession),
                SettingsTile(
                  icon: Icons.logout_rounded,
                  label: s.logout,
                  labelColor: context.colors.error,
                  iconColor: context.colors.error,
                  showChevron: false,
                  onTap: () => _confirmLogout(context, s),
                ),
                SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  label: s.deleteAccountTitle,
                  labelColor: context.colors.error,
                  iconColor: context.colors.error,
                  showChevron: false,
                  onTap: () => _confirmDeleteAccount(context),
                ),
                const SizedBox(height: AppSpacing.xl),
                _DangerZoneSection(isResetting: isResetting),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            );
          },
        ),
      ),
    );
  }

  String _languageSubtitle(String language) {
    for (final l in _languages) {
      if (l.$1 == language) return l.$2;
    }
    return language;
  }

  String _themeSubtitle(BuildContext context) {
    final s = AppStrings.of(context);
    final mode = getIt<ThemeNotifier>().value;
    return mode == ThemeMode.light
        ? s.themeLight
        : mode == ThemeMode.dark
            ? s.themeDark
            : s.themeSystem;
  }

  void _showLanguagePicker(
    BuildContext context,
    AppStrings s,
    UserModel user,
  ) {
    final bloc = context.read<SettingsBloc>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                0,
                AppSpacing.pagePadding,
                AppSpacing.lg,
              ),
              child: Text(s.selectLanguage, style: AppTypography.titleSm),
            ),
            ..._languages.map(
              (l) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                title: Text(l.$2, style: AppTypography.bodyMd),
                trailing: user.language == l.$1
                    ? const Icon(
                        Icons.check_rounded,
                        color: context.colors.primary,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  if (user.language != l.$1) {
                    getIt<LocaleNotifier>().setLanguage(l.$1);
                    getIt<SecureStorage>().saveLanguage(l.$1);
                    bloc.add(SettingsProfileUpdated({'language': l.$1}));
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, AppStrings s) {
    final notifier = getIt<ThemeNotifier>();
    final currentMode = notifier.value;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                0,
                AppSpacing.pagePadding,
                AppSpacing.lg,
              ),
              child: Text(s.selectTheme, style: AppTypography.titleSm),
            ),
            ..._themes.map((t) {
              final (mode, modeStr) = t;
              final label = mode == ThemeMode.light
                  ? s.themeLight
                  : mode == ThemeMode.dark
                      ? s.themeDark
                      : s.themeSystem;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                title: Text(label, style: AppTypography.bodyMd),
                trailing: currentMode == mode
                    ? Icon(
                        Icons.check_rounded,
                        color: context.colors.primary,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  if (currentMode != mode) {
                    notifier.setMode(mode);
                    getIt<SecureStorage>().saveThemeMode(modeStr);
                  }
                },
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceContainerHigh,
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

  void _confirmDeleteAccount(BuildContext context) {
    final s = AppStrings.of(context);
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surfaceContainerHigh,
        title: Text(s.deleteAccountTitle, style: AppTypography.titleSm),
        content: Text(
          s.deleteUserAccountContent,
          style: AppTypography.bodyMd.copyWith(color: context.colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.deleteAccountTitle,
                style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        try {
          await getIt<AuthRepository>().deleteAccount();
          if (context.mounted) context.go(RouteNames.login);
        } catch (e) {
          if (context.mounted) {
            String msg = 'Hesap silinemedi. Lütfen tekrar deneyin.';
            if (e is DioException) {
              final data = e.response?.data;
              if (data is Map && data['message'] != null) {
                msg = data['message'].toString();
              } else if (e.response?.statusCode != null) {
                msg = 'HTTP ${e.response!.statusCode}: $msg';
              }
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: context.colors.error),
            );
          }
        }
      }
    });
  }

  void _confirmLogout(BuildContext context, AppStrings s) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surfaceContainerHigh,
        title: Text(s.logoutConfirmTitle, style: AppTypography.titleSm),
        content: Text(
          s.logoutConfirmContent,
          style: AppTypography.bodyMd.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              s.logout,
              style: TextStyle(color: context.colors.error),
            ),
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

class _DangerZoneSection extends StatelessWidget {
  const _DangerZoneSection({required this.isResetting});

  final bool isResetting;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.error.withAlpha(20),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  bottom: AppSpacing.sm,
                ),
                child: Text(
                  s.sectionDangerZone.toUpperCase(),
                  style: AppTypography.labelSm.copyWith(
                    color: context.colors.error,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  onTap: isResetting
                      ? null
                      : () => _showResetDataSheet(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_forever_outlined,
                          color: context.colors.error,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.resetAllDataTitle,
                                style: AppTypography.bodyMd.copyWith(
                                  color: context.colors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                s.resetAllDataSubtitle,
                                style: AppTypography.bodyMd.copyWith(
                                  color: context.colors.error.withAlpha(180),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isResetting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: context.colors.error,
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showResetDataSheet(BuildContext context) {
    final bloc = context.read<SettingsBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const ResetDataSheet(),
      ),
    );
  }
}
