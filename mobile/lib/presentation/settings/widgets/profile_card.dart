import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/core/constants/api_endpoints.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/widgets/authenticated_image.dart';
import 'package:wallet_app/data/models/user_model.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
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
          color: context.colors.surfaceContainerHigh,
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
                    color: context.colors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: _buildAvatar(user, initials),
                ),
                if (isSaving)
                  const Positioned.fill(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.primary,
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
                    style: AppTypography.bodySm.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel user, String initials) {
    final googleUrl = user.googleAvatarUrl;
    if (googleUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: googleUrl,
          fit: BoxFit.cover,
          placeholder: (context, _) => const CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colors.primary,
          ),
          errorWidget: (context, _, error) => _initialsWidget(initials),
        ),
      );
    }
    if (user.hasLocalAvatar) {
      return ClipOval(
        child: AuthenticatedImage(
          urlPath: ApiEndpoints.meAvatar,
          cacheKey: user.avatarUrl,
          fit: BoxFit.cover,
          placeholder: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.primary,
            ),
          ),
          errorWidget: _initialsWidget(initials),
        ),
      );
    }
    return _initialsWidget(initials);
  }

  Widget _initialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: AppTypography.titleSm.copyWith(color: context.colors.primary),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
