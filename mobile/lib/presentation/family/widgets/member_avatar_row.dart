import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/family_model.dart';

class MemberAvatarRow extends StatelessWidget {
  const MemberAvatarRow({
    super.key,
    required this.members,
    this.maxVisible = 4,
    this.showRoles = false,
  });

  final List<FamilyMemberModel> members;
  final int maxVisible;
  final bool showRoles;

  @override
  Widget build(BuildContext context) {
    if (showRoles) {
      return Column(
        children: members
            .map((m) => _MemberListTile(member: m))
            .toList(),
      );
    }

    final visible = members.take(maxVisible).toList();
    final overflow = members.length - maxVisible;

    return Row(
      children: [
        SizedBox(
          height: 36,
          width: visible.length * 26.0 + 10,
          child: Stack(
            children: [
              for (var i = 0; i < visible.length; i++)
                Positioned(
                  left: i * 26.0,
                  child: _Avatar(member: visible[i], index: i),
                ),
            ],
          ),
        ),
        if (overflow > 0) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '+$overflow',
            style: AppTypography.bodySm,
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member, required this.index});

  final FamilyMemberModel member;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initials = member.name.isNotEmpty
        ? member.name.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';

    final avatarColors = [
      colors.primary,
      colors.secondary,
      colors.tertiary,
      colors.primaryContainer,
    ];
    final bg = avatarColors[index % avatarColors.length];

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 2),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: AppTypography.labelSm.copyWith(
            color: bg,
            letterSpacing: 0,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _MemberListTile extends StatelessWidget {
  const _MemberListTile({required this.member});

  final FamilyMemberModel member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initials = member.name.isNotEmpty
        ? member.name.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: AppTypography.labelSm.copyWith(
                  color: colors.primary,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: AppTypography.bodyMd),
                Text(
                  member.email,
                  style: AppTypography.bodySm,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: member.role == FamilyRole.OWNER
                  ? colors.primary.withValues(alpha: 0.15)
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              member.role == FamilyRole.OWNER
                  ? AppStrings.of(context).roleOwner
                  : AppStrings.of(context).roleMember,
              style: AppTypography.labelSm.copyWith(
                color: member.role == FamilyRole.OWNER
                    ? colors.primary
                    : colors.onSurfaceVariant,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
