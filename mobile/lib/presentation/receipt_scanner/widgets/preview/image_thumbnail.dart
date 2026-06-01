import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/theme/app_palette.dart';

class ImageThumbnail extends StatelessWidget {
  const ImageThumbnail({super.key, required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Image.file(
        File(imagePath),
        width: double.infinity,
        fit: BoxFit.fitWidth,
        errorBuilder: (ctx, obj, e) => Container(
          height: 200,
          color: colors.surfaceContainerHigh,
          child: Icon(
            Icons.receipt_long_outlined,
            color: colors.onSurfaceVariant,
            size: 48,
          ),
        ),
      ),
    );
  }
}
