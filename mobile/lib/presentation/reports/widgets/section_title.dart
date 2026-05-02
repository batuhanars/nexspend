import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/app_typography.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleSm.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
