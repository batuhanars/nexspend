import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/inflation_model.dart';

class InflationComparisonTable extends StatelessWidget {
  const InflationComparisonTable({
    super.key,
    required this.comparison,
  });

  final InflationComparisonModel comparison;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryRow(summary: comparison.summary),
        const SizedBox(height: AppSpacing.md),
        _TableHeader(),
        const SizedBox(height: AppSpacing.sm),
        ...comparison.rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ComparisonRow(row: row),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});
  final InflationComparisonSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryChip(
          count: summary.categoriesBelow,
          label: 'Altında',
          color: AppColors.secondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        _SummaryChip(
          count: summary.categoriesEqual,
          label: 'Dengede',
          color: AppColors.onSurface,
        ),
        const SizedBox(width: AppSpacing.sm),
        _SummaryChip(
          count: summary.categoriesAbove,
          label: 'Üstünde',
          color: AppColors.tertiary,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: AppTypography.titleSm.copyWith(color: color, fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'KATEGORİ',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              'SENİN %',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 10,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              'TÜFE %',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 10,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.row});
  final InflationComparisonRowModel row;

  Color get _statusColor => switch (row.status) {
        InflationComparisonStatus.BELOW => AppColors.secondary,
        InflationComparisonStatus.ABOVE => AppColors.tertiary,
        InflationComparisonStatus.EQUAL => AppColors.onSurface,
      };

  String get _statusLabel => switch (row.status) {
        InflationComparisonStatus.BELOW => 'Altında',
        InflationComparisonStatus.ABOVE => 'Üstünde',
        InflationComparisonStatus.EQUAL => 'Dengede',
      };

  @override
  Widget build(BuildContext context) {
    final userRate = row.userChangeRate;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.categoryName,
              style: AppTypography.bodyMd,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              userRate != null
                  ? '${userRate >= 0 ? '+' : ''}${userRate.toStringAsFixed(1)}%'
                  : '—',
              style: AppTypography.bodySm.copyWith(
                color: _statusColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '+${row.inflationRate.toStringAsFixed(1)}%',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 36,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              _statusLabel,
              style: AppTypography.labelSm.copyWith(
                color: _statusColor,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
