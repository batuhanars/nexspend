import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/family_model.dart';

class InviteStatusBadge extends StatelessWidget {
  const InviteStatusBadge({super.key, required this.status});

  final InviteStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      InviteStatus.PENDING => ('Bekliyor', AppColors.tertiary),
      InviteStatus.ACCEPTED => ('Kabul Edildi', AppColors.secondary),
      InviteStatus.REJECTED => ('Reddedildi', AppColors.onSurfaceVariant),
      InviteStatus.EXPIRED => ('Süresi Doldu', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(color: color, letterSpacing: 0),
      ),
    );
  }
}
