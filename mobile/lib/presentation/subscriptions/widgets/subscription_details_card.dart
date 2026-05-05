import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/subscription_model.dart';

class SubscriptionDetailsCard extends StatelessWidget {
  const SubscriptionDetailsCard({super.key, required this.sub});
  final SubscriptionModel sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detaylar', style: AppTypography.titleSm),
          const SizedBox(height: AppSpacing.md),
          if (sub.description != null) ...[
            SubscriptionDetailRow(label: 'Açıklama', value: sub.description!),
            const Divider(
                color: AppColors.surfaceContainerHighest, height: 1),
          ],
          if (sub.categoryName != null) ...[
            SubscriptionDetailRow(label: 'Kategori', value: sub.categoryName!),
            const Divider(
                color: AppColors.surfaceContainerHighest, height: 1),
          ],
          if (sub.accountName != null) ...[
            SubscriptionDetailRow(label: 'Hesap', value: sub.accountName!),
            const Divider(
                color: AppColors.surfaceContainerHighest, height: 1),
          ],
          SubscriptionDetailRow(
            label: 'Otomatik Kesinti',
            value: sub.autoDeduct ? 'Açık' : 'Kapalı',
          ),
          if (sub.nextRenewalDate != null) ...[
            const Divider(
                color: AppColors.surfaceContainerHighest, height: 1),
            SubscriptionDetailRow(
              label: 'Sonraki Yenilenme',
              value: _formatDate(sub.nextRenewalDate!),
              valueColor:
                  sub.isRenewingSoon ? AppColors.warning : null,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySm
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          Text(
            value,
            style: AppTypography.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
