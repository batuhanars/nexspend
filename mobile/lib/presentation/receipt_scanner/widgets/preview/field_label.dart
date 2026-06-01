import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/theme/app_palette.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.labelSm.copyWith(color: context.colors.onSurfaceVariant),
  );
}
