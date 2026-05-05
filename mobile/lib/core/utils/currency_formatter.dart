import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String _code = 'TRY';
  static NumberFormat? _fmt;
  static NumberFormat? _fmtNoDecimal;

  static void setCurrency(String code) {
    if (_code == code) return;
    _code = code;
    _fmt = null;
    _fmtNoDecimal = null;
  }

  static NumberFormat get _format => _fmt ??= _build(2);
  static NumberFormat get _formatND => _fmtNoDecimal ??= _build(0);

  static NumberFormat _build(int decimals) => switch (_code) {
        'USD' => NumberFormat.currency(
            locale: 'en_US', symbol: r'$', decimalDigits: decimals),
        'EUR' => NumberFormat.currency(
            locale: 'de_DE', symbol: '€', decimalDigits: decimals),
        'GBP' => NumberFormat.currency(
            locale: 'en_GB', symbol: '£', decimalDigits: decimals),
        _ => NumberFormat.currency(
            locale: 'tr_TR', symbol: '₺', decimalDigits: decimals),
      };

  static String get _symbol => switch (_code) {
        'USD' => r'$',
        'EUR' => '€',
        'GBP' => '£',
        _ => '₺',
      };

  /// ₺45.230,00
  static String format(num amount) => _format.format(amount);

  /// ₺45.230
  static String formatNoDecimal(num amount) => _formatND.format(amount);

  /// +₺3.840,00  veya  -₺1.200,00
  static String formatSigned(num amount) {
    final formatted = _format.format(amount.abs());
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }

  /// Sadece sayı: "45.230,00"
  static String formatNumber(num amount) =>
      _format.format(amount).replaceFirst(_symbol, '').trim();

  /// Büyük tutarlar için kısaltma: ₺45,2B / ₺1,2M
  static String formatCompact(num amount) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    final sym = _symbol;
    if (abs >= 1_000_000) {
      return '$sign$sym${(abs / 1_000_000).toStringAsFixed(1)}M';
    } else if (abs >= 1_000) {
      return '$sign$sym${(abs / 1_000).toStringAsFixed(1)}B';
    }
    return format(amount);
  }
}
