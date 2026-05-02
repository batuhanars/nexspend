import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.wifi_off_rounded,
          size: 56,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          message,
          style:
              AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextButton(
          onPressed: onRetry,
          child: Text(
            'Tekrar Dene',
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
