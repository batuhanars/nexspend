import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/insight_rules.dart';
import '../../../core/theme/app_palette.dart';
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
    final colors = context.colors;
    final color = _severityColor(insight.severity, colors);

    return Dismissible(
      key: Key(insight.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Icon(Icons.close_rounded, color: colors.onSurfaceVariant),
      ),
      child: Container(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
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
                      style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
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
                icon: Icon(Icons.close_rounded, size: 18, color: colors.onSurfaceVariant),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity, AppPalette colors) {
    return switch (InsightSeverity.values.firstWhere(
      (e) => e.name == severity,
      orElse: () => InsightSeverity.info,
    )) {
      InsightSeverity.warning => colors.warning,
      InsightSeverity.success => colors.success,
      InsightSeverity.info => colors.primary,
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
