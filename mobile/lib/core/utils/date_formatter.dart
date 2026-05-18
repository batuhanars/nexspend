import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _trDayMonth = DateFormat('d MMMM', 'tr_TR');
  static final _enDayMonth = DateFormat('d MMMM', 'en_US');
  static final _trDayMonthYear = DateFormat('d MMMM yyyy', 'tr_TR');
  static final _enDayMonthYear = DateFormat('d MMMM yyyy', 'en_US');
  static final _trDayMonthShort = DateFormat('d MMM', 'tr_TR');
  static final _enDayMonthShort = DateFormat('d MMM', 'en_US');
  static final _trFullDateTime = DateFormat('d MMM yyyy, HH:mm', 'tr_TR');
  static final _enFullDateTime = DateFormat('d MMM yyyy, HH:mm', 'en_US');
  static final _time = DateFormat('HH:mm');

  static bool _isEn(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en';

  /// 15 January 2026 / 15 Ocak 2026
  static String formatLong(DateTime date, BuildContext context) =>
      (_isEn(context) ? _enDayMonthYear : _trDayMonthYear).format(date);

  /// 15 January / 15 Ocak
  static String formatShort(DateTime date, BuildContext context) =>
      (_isEn(context) ? _enDayMonth : _trDayMonth).format(date);

  /// 15 Jan / 15 Oca
  static String formatMini(DateTime date, BuildContext context) =>
      (_isEn(context) ? _enDayMonthShort : _trDayMonthShort).format(date);

  /// 14:30 — saat formatı locale-agnostik
  static String formatTime(DateTime date) => _time.format(date.toLocal());

  /// 15 Jan 2026, 14:30 / 15 Oca 2026, 14:30
  static String formatFull(DateTime date, BuildContext context) =>
      (_isEn(context) ? _enFullDateTime : _trFullDateTime)
          .format(date.toLocal());

  /// TODAY / YESTERDAY / 15 JANUARY — BUGÜN / DÜN / 15 OCAK
  static String formatGroupHeader(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final local = date.toLocal();
    final d = DateTime(local.year, local.month, local.day);
    final isEn = _isEn(context);

    if (d == today) return isEn ? 'TODAY' : 'BUGÜN';
    if (d == yesterday) return isEn ? 'YESTERDAY' : 'DÜN';

    if (d.year == now.year) {
      return (isEn ? _enDayMonth : _trDayMonth).format(local).toUpperCase();
    }
    return (isEn ? _enDayMonthYear : _trDayMonthYear)
        .format(local)
        .toUpperCase();
  }
}
