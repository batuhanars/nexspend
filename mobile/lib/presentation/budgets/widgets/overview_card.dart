import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/budget_model.dart';

class OverviewCard extends StatelessWidget {
  const OverviewCard({super.key, required this.overview});
  final BudgetOverviewModel overview;

  Color get _arcColor {
    final pct = overview.percentage;
    if (pct >= 100) return const Color(0xFFEF5350);
    if (pct >= 90) return const Color(0xFFFF9800);
    if (pct >= 80) return const Color(0xFFFFB68F);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _ArcPainter(
                    percentage: overview.percentage,
                    color: _arcColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '%${overview.percentage}',
                      style: AppTypography.headlineMd.copyWith(
                        color: _arcColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'harcandı',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Toplam Bütçe',
                  value: CurrencyFormatter.format(overview.totalBudget),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatChip(
                  label: 'Harcanan',
                  value: CurrencyFormatter.format(overview.totalSpent),
                  color: AppColors.tertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatChip(
                  label: 'Kalan',
                  value: CurrencyFormatter.format(overview.remaining),
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.bodySm.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.percentage, required this.color});
  final int percentage;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 10;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final bgPaint = Paint()
      ..color = AppColors.surfaceContainerHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final pct = percentage.clamp(0, 100) / 100;
    if (pct > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * pct,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.percentage != percentage || old.color != color;
}
