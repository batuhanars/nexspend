import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/budget_model.dart';

class OverviewCard extends StatelessWidget {
  const OverviewCard({super.key, required this.overview});
  final BudgetOverviewModel overview;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = overview.percentage;
    // Bütçe durum renkleri: EXCEEDED → danger, CRITICAL → warning, WARNING → expense, OK → primary
    final arcColor = pct >= 100
        ? colors.danger
        : pct >= 90
            ? colors.warning
            : pct >= 80
                ? colors.expense
                : colors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
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
                    color: arcColor,
                    bgColor: colors.surfaceContainerHighest,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '%${overview.percentage}',
                      style: AppTypography.headlineMd.copyWith(
                        color: arcColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AppStrings.of(context).spentArc,
                      style: AppTypography.labelSm.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Builder(
            builder: (context) {
              final s = AppStrings.of(context);
              return Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: s.totalBudget,
                      value: CurrencyFormatter.format(overview.totalBudget),
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatChip(
                      label: s.spent,
                      value: CurrencyFormatter.format(overview.totalSpent),
                      color: colors.expense,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatChip(
                      label: s.remaining,
                      value: CurrencyFormatter.format(overview.remaining),
                      color: colors.income,
                    ),
                  ),
                ],
              );
            },
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
            color: context.colors.onSurfaceVariant,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// §8 — CustomPainter context'siz: renk constructor'dan alınır.
class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.percentage,
    required this.color,
    required this.bgColor,
  });
  final int percentage;
  final Color color;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 10;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final bgPaint = Paint()
      ..color = bgColor
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
      old.percentage != percentage || old.color != color || old.bgColor != bgColor;
}
