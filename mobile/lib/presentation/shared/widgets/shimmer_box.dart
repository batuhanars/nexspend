import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_palette.dart';

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.radius,
    this.shape = BoxShape.rectangle,
  });

  final double height;
  final double? width;
  final double? radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(radius ?? AppSpacing.radiusMd),
        shape: shape,
      ),
    );
  }
}
