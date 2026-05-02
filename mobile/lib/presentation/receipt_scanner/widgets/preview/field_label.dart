import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_typography.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
  );
}
