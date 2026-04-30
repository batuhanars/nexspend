import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _trFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  static final NumberFormat _trFormatNoDecimal = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 0,
  );

  /// ₺45.230,00
  static String format(num amount) => _trFormat.format(amount);

  /// ₺45.230
  static String formatNoDecimal(num amount) =>
      _trFormatNoDecimal.format(amount);

  /// +₺3.840,00  veya  -₺1.200,00
  static String formatSigned(num amount) {
    final formatted = _trFormat.format(amount.abs());
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }

  /// Sadece sayı: "45.230,00"
  static String formatNumber(num amount) =>
      _trFormat.format(amount).replaceFirst('₺', '').trim();

  /// Büyük tutarlar için kısaltma: ₺45,2B / ₺1,2M
  static String formatCompact(num amount) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (abs >= 1000000) {
      return '$sign₺${(abs / 1000000).toStringAsFixed(1)}M';
    } else if (abs >= 1000) {
      return '$sign₺${(abs / 1000).toStringAsFixed(1)}B';
    }
    return format(amount);
  }
}
