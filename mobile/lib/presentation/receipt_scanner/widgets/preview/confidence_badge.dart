import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:wallet_app/core/theme/app_palette.dart';

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({super.key, required this.confidence});
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = (confidence * 100).round();
    final color = pct >= 70
        ? colors.success
        : pct >= 40
        ? colors.warning
        : colors.error;

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
