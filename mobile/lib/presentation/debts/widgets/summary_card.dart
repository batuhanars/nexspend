import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/utils/currency_formatter.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.total,
    required this.remaining,
    required this.color,
    required this.icon,
  });
  final String label;
  final double total;
  final double remaining;
  final Color color;
  final IconData icon;

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
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: AppTypography.labelSm.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            CurrencyFormatter.format(remaining),
            style: AppTypography.titleSm.copyWith(color: AppColors.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Toplam: ${CurrencyFormatter.formatCompact(total)}',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
