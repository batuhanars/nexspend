import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          backgroundColor: AppColors.surfaceContainerHigh,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Google ile Devam Et',
              style: AppTypography.titleSm.copyWith(color: AppColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.22;
    final radius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double rad(double deg) => deg * math.pi / 180;

    // Blue: sağ taraf (barın bağlandığı yer), -8° → 62°
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, rad(-8), rad(70), false, paint);

    // Yellow: alt, 62° → 157°
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, rad(62), rad(95), false, paint);

    // Green: sol, 157° → 252°
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, rad(157), rad(95), false, paint);

    // Red: üst, 252° → 352°
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, rad(252), rad(100), false, paint);

    // Blue yatay bar (G'nin orta çıkıntısı)
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - strokeWidth * 0.15,
        center.dy - strokeWidth / 2,
        size.width / 2 + strokeWidth * 0.15,
        strokeWidth,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
