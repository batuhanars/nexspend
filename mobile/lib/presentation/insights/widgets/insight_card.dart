import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/insight_rules.dart';
import '../../../data/models/insight_model.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
    required this.onDismiss,
    this.compact = false,
  });

  final InsightModel insight;
  final VoidCallback onDismiss;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(insight.severity);

    return Dismissible(
      key: Key(insight.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
      ),
      child: Container(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SeverityIcon(severity: insight.severity, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.title,
                      style: AppTypography.titleSm,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis),
                  if (!compact) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      insight.message,
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.onSurfaceVariant),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    return switch (InsightSeverity.values.firstWhere(
      (e) => e.name == severity,
      orElse: () => InsightSeverity.info,
    )) {
      InsightSeverity.warning => AppColors.tertiary,
      InsightSeverity.success => AppColors.secondary,
      InsightSeverity.info => AppColors.primary,
    };
  }
}

class _SeverityIcon extends StatelessWidget {
  const _SeverityIcon({required this.severity, required this.color});

  final String severity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (InsightSeverity.values.firstWhere(
      (e) => e.name == severity,
      orElse: () => InsightSeverity.info,
    )) {
      InsightSeverity.warning => Icons.warning_amber_rounded,
      InsightSeverity.success => Icons.check_circle_outline_rounded,
      InsightSeverity.info => Icons.lightbulb_outline_rounded,
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
