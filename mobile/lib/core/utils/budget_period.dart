import '../../data/models/budget_model.dart';

class BudgetPeriodUtils {
  BudgetPeriodUtils._();

  /// startDate dahil, endDate dahil aralık.
  /// Backend period.utils.ts mantığıyla bire bir aynı.
  static DateTime computeEndDate(DateTime startDate, BudgetPeriod period) {
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    switch (period) {
      case BudgetPeriod.WEEKLY:
        return s.add(const Duration(days: 6));
      case BudgetPeriod.MONTHLY:
        return DateTime(s.year, s.month + 1, s.day)
            .subtract(const Duration(days: 1));
      case BudgetPeriod.YEARLY:
        return DateTime(s.year + 1, s.month, s.day)
            .subtract(const Duration(days: 1));
      case BudgetPeriod.CUSTOM:
        return startDate;
    }
  }
}
