import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const len = 24.0;
    const r = 8.0;
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left: arc from west (π) clockwise to north (3π/2)
    canvas.drawLine(const Offset(r, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, r), const Offset(0, len), paint);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, r * 2, r * 2),
      3.14,
      1.57,
      false,
      paint,
    );

    // Top-right: arc from north (3π/2) clockwise to east (2π)
    canvas.drawLine(
      Offset(size.width - len, 0),
      Offset(size.width - r, 0),
      paint,
    );
    canvas.drawLine(Offset(size.width, r), Offset(size.width, len), paint);
    canvas.drawArc(
      Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
      4.71,
      1.57,
      false,
      paint,
    );

    // Bottom-left: arc from west (π) counterclockwise to south (π/2)
    canvas.drawLine(
      Offset(0, size.height - len),
      Offset(0, size.height - r),
      paint,
    );
    canvas.drawLine(Offset(r, size.height), Offset(len, size.height), paint);
    canvas.drawArc(
      Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
      3.14,
      -1.57,
      false,
      paint,
    );

    // Bottom-right: arc from east (0) clockwise to south (π/2)
    canvas.drawLine(
      Offset(size.width - len, size.height),
      Offset(size.width - r, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - len),
      Offset(size.width, size.height - r),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2),
      0,
      1.57,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
