import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/theme/app_palette.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: colors.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.of(context).cameraStartFailed,
              style: AppTypography.titleSm.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: onRetry, child: Text(AppStrings.of(context).retry)),
          ],
        ),
      ),
    );
  }
}
