import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _dayMonth = DateFormat('d MMMM', 'tr_TR');
  static final _dayMonthYear = DateFormat('d MMMM yyyy', 'tr_TR');
  static final _dayMonthShort = DateFormat('d MMM', 'tr_TR');
  static final _time = DateFormat('HH:mm', 'tr_TR');
  static final _fullDateTime = DateFormat('d MMM yyyy, HH:mm', 'tr_TR');

  /// 15 Ocak 2026
  static String formatLong(DateTime date) => _dayMonthYear.format(date.toLocal());

  /// 15 Ocak
  static String formatShort(DateTime date) => _dayMonth.format(date.toLocal());

  /// 15 Oca
  static String formatMini(DateTime date) => _dayMonthShort.format(date.toLocal());

  /// 14:30
  static String formatTime(DateTime date) => _time.format(date.toLocal());

  /// 15 Oca 2026, 14:30
  static String formatFull(DateTime date) => _fullDateTime.format(date.toLocal());

  /// BUGÜN / DÜN / 15 Ocak — işlem listesi grup başlıkları için
  static String formatGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final local = date.toLocal();
    final d = DateTime(local.year, local.month, local.day);

    if (d == today) return 'BUGÜN';
    if (d == yesterday) return 'DÜN';
    if (d.year == now.year) return _dayMonth.format(local).toUpperCase();
    return _dayMonthYear.format(local).toUpperCase();
  }

  /// Kalan gün sayısı: "3 gün sonra" / "Bugün" / "2 gün önce"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = date.toLocal().difference(now).inDays;
    if (diff == 0) return 'Bugün';
    if (diff == 1) return 'Yarın';
    if (diff == -1) return 'Dün';
    if (diff > 0) return '$diff gün sonra';
    return '${diff.abs()} gün önce';
  }
}
