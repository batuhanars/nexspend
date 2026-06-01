import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../shared/widgets/split_amount_field.dart';

class AmountField extends StatelessWidget {
  const AmountField({super.key, required this.onChanged, this.initialValue});
  final ValueChanged<double?> onChanged;
  final double? initialValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.of(context).budgetAmountLabel,
          style: AppTypography.labelSm.copyWith(
            color: context.colors.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SplitAmountField(onChanged: onChanged, initialValue: initialValue),
      ],
    );
  }
}
