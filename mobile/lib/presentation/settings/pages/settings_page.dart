import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/storage/secure_storage.dart';
import 'package:wallet_app/core/utils/currency_notifier.dart';
import 'package:wallet_app/core/utils/locale_notifier.dart';
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

  static const _currencies = [
    ('TRY', '₺'),
    ('USD', r'$'),
    ('EUR', '€'),
    ('GBP', '£'),
  ];

  static const _languages = [
    ('tr', 'Türkçe'),
    ('en', 'English'),
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
              backgroundColor: AppColors.error,
            ),
          );
        }
        if (state is SettingsLoaded && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.settings, style: AppTypography.headlineSm),
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
                      child: Text(s.retry),
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
                ProfileCard(
                  user: user,
                  onEditTap: () => context.push(RouteNames.editProfile),
                  isSaving: isSaving,
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(s.sectionAccount),
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  label: s.editProfile,
                  onTap: () => context.push(RouteNames.editProfile),
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
                  icon: Icons.currency_exchange_rounded,
                  label: s.currency,
                  subtitle: _currencySubtitle(s, user.currency),
                  onTap: () => _showCurrencyPicker(context, s, user),
                ),
                SettingsTile(
                  icon: Icons.translate_rounded,
                  label: s.language,
                  subtitle: _languageSubtitle(user.language),
                  onTap: () => _showLanguagePicker(context, s, user),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(s.sectionTools),
                SettingsTile(
                  icon: Icons.receipt_long_outlined,
                  label: s.receiptHistory,
                  onTap: () => context.push(RouteNames.receiptHistory),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(s.sectionSecurity),
                if (user.hasPassword)
                  SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    label: s.changePassword,
                    onTap: () => _showChangePasswordSheet(context),
                  ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(s.sectionSession),
                SettingsTile(
                  icon: Icons.logout_rounded,
                  label: s.logout,
                  labelColor: AppColors.error,
                  iconColor: AppColors.error,
                  showChevron: false,
                  onTap: () => _confirmLogout(context, s),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            );
          },
        ),
      ),
    );
  }

  String _currencySubtitle(AppStrings s, String currency) {
    final labels = {
      'TRY': '₺ ${s.currencyTRY}',
      'USD': r'$ ' + s.currencyUSD,
      'EUR': '€ ${s.currencyEUR}',
      'GBP': '£ ${s.currencyGBP}',
    };
    return labels[currency] ?? currency;
  }

  String _languageSubtitle(String language) {
    for (final l in _languages) {
      if (l.$1 == language) return l.$2;
    }
    return language;
  }

  void _showCurrencyPicker(
    BuildContext context,
    AppStrings s,
    UserModel user,
  ) {
    final bloc = context.read<SettingsBloc>();
    final currencyLabels = {
      'TRY': s.currencyTRY,
      'USD': s.currencyUSD,
      'EUR': s.currencyEUR,
      'GBP': s.currencyGBP,
    };
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
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
              child: Text(s.selectCurrency, style: AppTypography.titleSm),
            ),
            ..._currencies.map(
              (c) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      c.$2,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.primary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
                title: Text(
                  currencyLabels[c.$1] ?? c.$1,
                  style: AppTypography.bodyMd,
                ),
                subtitle: Text(
                  c.$1,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                trailing: user.currency == c.$1
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.primary,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  if (user.currency != c.$1) {
                    bloc.add(SettingsProfileUpdated({'currency': c.$1}));
                    getIt<CurrencyNotifier>().setCurrency(c.$1);
                    getIt<SecureStorage>().saveCurrency(c.$1);
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

  void _showLanguagePicker(
    BuildContext context,
    AppStrings s,
    UserModel user,
  ) {
    final bloc = context.read<SettingsBloc>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
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
                        color: AppColors.primary,
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

  void _confirmLogout(BuildContext context, AppStrings s) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(s.logoutConfirmTitle, style: AppTypography.titleSm),
        content: Text(
          s.logoutConfirmContent,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
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
              style: TextStyle(color: AppColors.error),
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
