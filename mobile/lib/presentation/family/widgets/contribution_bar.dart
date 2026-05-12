import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/family_model.dart';

class ContributionBar extends StatelessWidget {
  const ContributionBar({
    super.key,
    required this.member,
    required this.colorIndex,
    this.expanded = false,
  });

  final ContributionMemberModel member;
  final int colorIndex;
  final bool expanded;

  static const _barColors = [AppColors.primary, AppColors.secondary];

  @override
  Widget build(BuildContext context) {
    final color = _barColors[colorIndex % _barColors.length];
    final pct = (member.percentage / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(member.name, style: AppTypography.bodyMd),
            ),
            Text(
              CurrencyFormatter.format(member.totalAmount),
              style: AppTypography.bodyMd,
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 44,
              child: Text(
                '%${member.percentage.toStringAsFixed(1)}',
                style: AppTypography.bodySm.copyWith(color: color),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        if (expanded && member.byCategory.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ...member.byCategory.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      cat.categoryName,
                      style: AppTypography.bodySm,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(cat.amount),
                    style: AppTypography.bodySm,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
