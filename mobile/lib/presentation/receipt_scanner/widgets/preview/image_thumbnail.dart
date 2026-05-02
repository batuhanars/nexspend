import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';

class ImageThumbnail extends StatelessWidget {
  const ImageThumbnail({super.key, required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Image.file(
        File(imagePath),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, obj, e) => Container(
          height: 200,
          color: AppColors.surfaceContainerHigh,
          child: const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.onSurfaceVariant,
            size: 48,
          ),
        ),
      ),
    );
  }
}
