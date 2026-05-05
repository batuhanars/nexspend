import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';

class AmountField extends StatefulWidget {
  const AmountField({super.key, required this.onChanged});
  final ValueChanged<double?> onChanged;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  final _intCtrl = TextEditingController();
  final _decCtrl = TextEditingController();
  final _decFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _intCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _intCtrl.dispose();
    _decCtrl.dispose();
    _decFocus.dispose();
    super.dispose();
  }

  void _notify() {
    final i = _intCtrl.text;
    final d = _decCtrl.text;
    if (i.isEmpty && d.isEmpty) {
      widget.onChanged(null);
    } else {
      widget.onChanged(
        double.tryParse('${i.isEmpty ? '0' : i}.${d.isEmpty ? '0' : d}'),
      );
    }
  }

  double _intWidth() {
    final tp = TextPainter(
      text: TextSpan(
        text: _intCtrl.text.isEmpty ? '0' : _intCtrl.text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 56,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return (tp.width + 8).clamp(50.0, 220.0);
  }

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;

    const numStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 56,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurface,
      height: 1.0,
    );

    final hintStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 56,
      fontWeight: FontWeight.w300,
      color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
      height: 1.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.of(context).budgetAmountLabel,
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                '₺',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: color,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: _intWidth(),
              child: TextField(
                controller: _intCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => _decFocus.requestFocus(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _notify(),
                textAlign: TextAlign.right,
                style: numStyle,
                cursorColor: color,
                cursorWidth: 2,
                cursorHeight: 52,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: hintStyle,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                ',',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.45),
                  height: 1.0,
                ),
              ),
            ),
            SizedBox(
              width: 72,
              child: TextField(
                controller: _decCtrl,
                focusNode: _decFocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: (_) => _notify(),
                textAlign: TextAlign.left,
                style: numStyle,
                cursorColor: color,
                cursorWidth: 2,
                cursorHeight: 52,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '00',
                  hintStyle: hintStyle,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0x00BAC3FF),
                Color(0xB3BAC3FF),
                Color(0x00BAC3FF),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
