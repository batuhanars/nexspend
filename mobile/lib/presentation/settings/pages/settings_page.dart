import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../navigation/route_names.dart';
import '../bloc/settings_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsBloc(userRepository: getIt<UserRepository>())
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
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
                    Text(state.message,
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.tonal(
                      onPressed: () => context
                          .read<SettingsBloc>()
                          .add(const SettingsLoadRequested()),
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
                _ProfileCard(
                  user: user,
                  onEditTap: () => context.push(RouteNames.editProfile),
                  isSaving: isSaving,
                ),
                const SizedBox(height: AppSpacing.lg),
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
                _SectionHeader('Tercihler'),
                _SwitchTile(
                  icon: Icons.notifications_outlined,
                  label: 'Bildirimler',
                  value: user.notificationsEnabled,
                  onChanged: isSaving
                      ? null
                      : (v) => context.read<SettingsBloc>().add(
                            SettingsToggleChanged(
                                field: 'notifications', value: v),
                          ),
                ),
                _SwitchTile(
                  icon: Icons.fingerprint_rounded,
                  label: 'Biyometrik Giriş',
                  value: user.biometricEnabled,
                  onChanged: isSaving
                      ? null
                      : (v) => context.read<SettingsBloc>().add(
                            SettingsToggleChanged(
                                field: 'biometric', value: v),
                          ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader('Güvenlik'),
                if (user.hasPassword)
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Şifre Değiştir',
                    onTap: () => _showChangePasswordSheet(context),
                  ),
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader('Oturum'),
                _SettingsTile(
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
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: const _ChangePasswordSheet(),
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
          style:
              AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Çıkış Yap',
                style: TextStyle(color: AppColors.error)),
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

// ── Profil kartı ───────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.onEditTap,
    required this.isSaving,
  });

  final UserModel user;
  final VoidCallback onEditTap;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(user.fullName);
    return GestureDetector(
      onTap: onEditTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: user.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _initialsWidget(initials),
                          ),
                        )
                      : _initialsWidget(initials),
                ),
                if (isSaving)
                  const Positioned.fill(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: AppTypography.titleSm),
                  Text(
                    user.email,
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: AppTypography.titleSm.copyWith(color: AppColors.primary),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ── Ayarlar tile'ları ──────────────────────────────────────────────────────

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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
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

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      leading: Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
      title: Text(label, style: AppTypography.bodyMd),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
      ),
    );
  }
}

// ── Şifre değiştirme bottom sheet ─────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_currentCtrl.text.isEmpty ||
        _newCtrl.text.isEmpty ||
        _confirmCtrl.text.isEmpty) return;
    if (_newCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni şifreler eşleşmiyor.')),
      );
      return;
    }
    if (_newCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre en az 8 karakter olmalı.')),
      );
      return;
    }
    context.read<SettingsBloc>().add(SettingsPasswordChanged(
          currentPassword: _currentCtrl.text,
          newPassword: _newCtrl.text,
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xl,
        AppSpacing.pagePadding,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Şifre Değiştir', style: AppTypography.headlineSm),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _PasswordField(
            ctrl: _currentCtrl,
            hint: 'Mevcut şifre',
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: AppSpacing.md),
          _PasswordField(
            ctrl: _newCtrl,
            hint: 'Yeni şifre',
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: AppSpacing.md),
          _PasswordField(
            ctrl: _confirmCtrl,
            hint: 'Yeni şifre tekrar',
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
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
      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.onSurfaceVariant, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            size: 20, color: AppColors.onSurfaceVariant),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: AppColors.onSurfaceVariant,
          ),
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
      ),
    );
  }
}
