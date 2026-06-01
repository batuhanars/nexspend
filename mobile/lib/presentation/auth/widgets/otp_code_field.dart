import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_palette.dart';

/// OTP / sıfırlama kodu için kare kutucuk dizini. Görsel olarak `length` adet
/// kutucuk gösterir, arka planda tek bir görünmez TextField input alır — bu
/// sayede paste, autofill ve klavye davranışı out-of-the-box çalışır; focus
/// yönetimi ve `RawKeyboardListener` gerekmez.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
    this.autofocus = true,
    this.errorText,
  });

  final TextEditingController controller;
  final int length;

  /// Kod tamamlandığında (length'e ulaştığında) çağrılır. `null` bırakırsan
  /// kullanıcı butona basana kadar bir şey olmaz.
  final ValueChanged<String>? onCompleted;

  final bool autofocus;
  final String? errorText;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_handleChange);
  }

  void _handleChange() {
    if (mounted) setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 64,
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(widget.length, (i) {
                    final char = i < text.length ? text[i] : '';
                    final isFilled = char.isNotEmpty;
                    final isActive = !isFilled && i == text.length;
                    return _DigitBox(
                      char: char,
                      isFilled: isFilled,
                      isActive: isActive && _focusNode.hasFocus,
                      hasError: hasError,
                    );
                  }),
                ),
                // Görünmez TextField — fokus, paste, autofill ve klavye davranışı
                // bunun üstünden çalışır. Opacity 0 + IgnorePointer:false.
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      autofocus: widget.autofocus,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: widget.length,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(widget.length),
                      ],
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: context.colors.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.char,
    required this.isFilled,
    required this.isActive,
    required this.hasError,
  });

  final String char;
  final bool isFilled;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderColor = hasError
        ? colors.error
        : isActive
            ? colors.primary
            : Colors.transparent;
    final bg = isFilled
        ? colors.primary.withValues(alpha: 0.10)
        : colors.surfaceContainerHighest;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: borderColor,
          width: isActive || hasError ? 1.5 : 1,
        ),
        boxShadow: isActive && !hasError
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
          height: 1.0,
        ),
      ),
    );
  }
}
