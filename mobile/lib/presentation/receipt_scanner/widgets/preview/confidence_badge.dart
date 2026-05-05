import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({super.key, required this.confidence});
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    final color = pct >= 70
        ? AppColors.secondary
        : pct >= 40
        ? AppColors.tertiary
        : AppColors.error;

    return Row(
      children: [
        Icon(Icons.auto_awesome, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          AppStrings.of(context).ocrConfidence(pct),
          style: AppTypography.labelSm.copyWith(color: color),
        ),
      ],
    );
  }
}
