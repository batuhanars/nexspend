import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/subscription_model.dart';

class SubscriptionDetailsCard extends StatelessWidget {
  const SubscriptionDetailsCard({super.key, required this.sub});
  final SubscriptionModel sub;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.detailsCardTitle, style: AppTypography.titleSm),
          const SizedBox(height: AppSpacing.md),
          if (sub.description != null) ...[
            SubscriptionDetailRow(
              label: s.descriptionLabel,
              value: sub.description!,
            ),
            Divider(color: colors.surfaceContainerHighest, height: 1),
          ],
          if (sub.categoryName != null) ...[
            SubscriptionDetailRow(
              label: s.categoryLabel,
              value: sub.categoryName!,
            ),
            Divider(color: colors.surfaceContainerHighest, height: 1),
          ],
          if (sub.accountName != null) ...[
            SubscriptionDetailRow(
              label: s.accountLabel,
              value: sub.accountName!,
            ),
            Divider(color: colors.surfaceContainerHighest, height: 1),
          ],
          // Hatırlatma her iki tür için
          SubscriptionDetailRow(
            label: s.reminderDaysBeforeLabel,
            value: s.reminderDaysOption(sub.reminderDaysBefore),
          ),
          if (sub.nextRenewalDate != null) ...[
            Divider(color: colors.surfaceContainerHighest, height: 1),
            SubscriptionDetailRow(
              label: s.nextRenewalLabel,
              value: _formatDate(sub.nextRenewalDate!),
              valueColor: sub.isRenewingSoon ? colors.warning : null,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class SubscriptionDetailRow extends StatelessWidget {
  const SubscriptionDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySm.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
