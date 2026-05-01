import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/user_repository.dart';
import '../bloc/settings_bloc.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in BlocProvider only if there isn't one higher in the tree
    return BlocProvider(
      create: (_) => SettingsBloc(userRepository: getIt<UserRepository>())
        ..add(const SettingsLoadRequested()),
      child: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsLoaded && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );
          }
          if (state is SettingsLoaded && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading || state is SettingsInitial) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final user = state is SettingsLoaded
              ? state.user
              : (state as SettingsSaving).user;
          final isSaving = state is SettingsSaving;

          if (!_initialized) {
            _nameController.text = user.fullName;
            _initialized = true;
          }

          final initials = _getInitials(user.fullName);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Profili Düzenle'),
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              actions: [
                if (isSaving)
                  const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.lg),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _save,
                    child: Text(
                      'Kaydet',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              children: [
                const SizedBox(height: AppSpacing.xl),
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
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
                                      _InitialsWidget(initials: initials),
                                ),
                              )
                            : _InitialsWidget(initials: initials),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => _pickAvatar(context),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.surface, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 16,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.avatarUrl != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: TextButton(
                      onPressed: isSaving
                          ? null
                          : () => context
                              .read<SettingsBloc>()
                              .add(const SettingsAvatarDeleted()),
                      child: Text(
                        'Fotoğrafı Kaldır',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                // Ad Soyad
                _label('Ad Soyad'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _nameController,
                  enabled: !isSaving,
                  style: const TextStyle(
                      color: AppColors.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Adınızı girin',
                    hintStyle: const TextStyle(
                        color: AppColors.onSurfaceVariant, fontSize: 14),
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        size: 20, color: AppColors.onSurfaceVariant),
                    filled: true,
                    fillColor: AppColors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _label('E-posta'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          size: 20, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'E-posta adresi değiştirilemez',
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    context.read<SettingsBloc>().add(
          SettingsProfileUpdated({'fullName': name}),
        );
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Fotoğraf Seç', style: AppTypography.titleSm),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(ImageSource.camera),
            child: const Text('Kamera'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(ImageSource.gallery),
            child: const Text('Galeri'),
          ),
        ],
      ),
    );
    if (source == null || !context.mounted) return;
    final image = await picker.pickImage(source: source, maxWidth: 800);
    if (image == null || !context.mounted) return;
    context.read<SettingsBloc>().add(SettingsAvatarUploaded(image.path));
  }

  Widget _label(String text) => Text(
        text,
        style: AppTypography.labelSm
            .copyWith(color: AppColors.onSurfaceVariant),
      );

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _InitialsWidget extends StatelessWidget {
  const _InitialsWidget({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: AppTypography.headlineSm.copyWith(color: AppColors.primary),
      ),
    );
  }
}
