import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = type == 'INCOME'
        ? colors.income
        : type == 'TRANSFER'
            ? colors.primary
            : colors.expense;
    return SplitAmountField(
      onChanged: onChanged,
      color: color,
      initialValue: initialValue,
    );
  }
}
