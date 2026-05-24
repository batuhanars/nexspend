import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/split_amount_field.dart';

class TransactionAmountField extends StatelessWidget {
  const TransactionAmountField({
    super.key,
    required this.onChanged,
    required this.type,
    this.initialValue,
  });
  final ValueChanged<double?> onChanged;
  final String type;
  final double? initialValue;

  Color get _color => type == 'INCOME'
      ? AppColors.secondary
      : type == 'TRANSFER'
          ? AppColors.primary
          : AppColors.tertiary;

  @override
  Widget build(BuildContext context) {
    return SplitAmountField(
      onChanged: onChanged,
      color: _color,
      initialValue: initialValue,
    );
  }
}
