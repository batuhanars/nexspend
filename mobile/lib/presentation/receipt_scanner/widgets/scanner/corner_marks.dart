import 'package:flutter/material.dart';
import 'package:wallet_app/presentation/receipt_scanner/utils/corner_painter.dart';

class CornerMarks extends StatelessWidget {
  const CornerMarks({super.key, required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: CornerPainter()),
    );
  }
}
