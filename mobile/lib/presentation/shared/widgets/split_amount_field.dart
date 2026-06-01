import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_palette.dart';

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final formatted = format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String format(String digits) {
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

class SplitAmountField extends StatefulWidget {
  const SplitAmountField({
    super.key,
    required this.onChanged,
    this.color = AppColors.primary,
    this.autofocus = true,
    this.initialValue,
  });

  final ValueChanged<double?> onChanged;
  final Color color;
  final bool autofocus;
  final double? initialValue;

  @override
  State<SplitAmountField> createState() => _SplitAmountFieldState();
}

class _SplitAmountFieldState extends State<SplitAmountField> {
  final _intCtrl = TextEditingController();
  final _decCtrl = TextEditingController();
  final _decFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue! > 0) {
      final parts = widget.initialValue!.toStringAsFixed(2).split('.');
      _intCtrl.text = ThousandsFormatter.format(parts[0]);
      _decCtrl.text = parts[1];
    }
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
    final i = _intCtrl.text.replaceAll('.', '');
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

  static const _noBorder = InputBorder.none;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final colors = context.colors;

    final numStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 56,
      fontWeight: FontWeight.w700,
      color: colors.onSurface,
      height: 1.0,
    );

    final hintStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 56,
      fontWeight: FontWeight.w300,
      color: colors.onSurface.withValues(alpha: 0.15),
      height: 1.0,
    );

    final baseDecoration = InputDecoration(
      border: _noBorder,
      enabledBorder: _noBorder,
      focusedBorder: _noBorder,
      errorBorder: _noBorder,
      focusedErrorBorder: _noBorder,
      filled: false,
      isDense: true,
      contentPadding: EdgeInsets.zero,
      hintStyle: hintStyle,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => _decFocus.requestFocus(),
                inputFormatters: [ThousandsFormatter()],
                onChanged: (_) => _notify(),
                textAlign: TextAlign.right,
                style: numStyle,
                cursorColor: color,
                cursorWidth: 2,
                cursorHeight: 52,
                decoration: baseDecoration.copyWith(hintText: '0'),
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
                  color: colors.onSurfaceVariant.withValues(alpha: 0.45),
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
                decoration: baseDecoration.copyWith(hintText: '00'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0),
                color.withValues(alpha: 0.7),
                color.withValues(alpha: 0),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
