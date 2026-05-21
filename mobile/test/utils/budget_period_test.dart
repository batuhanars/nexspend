import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/utils/budget_period.dart';
import 'package:wallet_app/data/models/budget_model.dart';

void main() {
  group('BudgetPeriodUtils.computeEndDate', () {
    test('WEEKLY: startDate + 6 days', () {
      final start = DateTime(2026, 5, 1);
      final end = BudgetPeriodUtils.computeEndDate(start, BudgetPeriod.WEEKLY);
      expect(end, DateTime(2026, 5, 7));
    });

    test('WEEKLY: end of month boundary', () {
      final start = DateTime(2026, 5, 27);
      final end = BudgetPeriodUtils.computeEndDate(start, BudgetPeriod.WEEKLY);
      expect(end, DateTime(2026, 6, 2));
    });

    test('MONTHLY: last day of same month', () {
      final start = DateTime(2026, 5, 1);
      final end = BudgetPeriodUtils.computeEndDate(start, BudgetPeriod.MONTHLY);
      expect(end, DateTime(2026, 5, 31));
    });

    test('MONTHLY: mid-month start', () {
      final start = DateTime(2026, 5, 15);
      final end = BudgetPeriodUtils.computeEndDate(start, BudgetPeriod.MONTHLY);
      expect(end, DateTime(2026, 6, 14));
    });

    test('MONTHLY: handles December → January year rollover', () {
      final start = DateTime(2026, 12, 1);
      final end = BudgetPeriodUtils.computeEndDate(start, BudgetPeriod.MONTHLY);
      expect(end, DateTime(2026, 12, 31));
    });

    test('YEARLY: same day next year minus one day', () {
      final start = DateTime(2026, 5, 1);
      final end = BudgetPeriodUtils.computeEndDate(start, BudgetPeriod.YEARLY);
      expect(end, DateTime(2027, 4, 30));
    });

    test('YEARLY: leap year boundary (Feb 28 start)', () {
      final start = DateTime(2026, 2, 28);
      final end = BudgetPeriodUtils.computeEndDate(start, BudgetPeriod.YEARLY);
      expect(end, DateTime(2027, 2, 27));
    });

    test('CUSTOM: returns startDate unchanged', () {
      final start = DateTime(2026, 5, 1);
      final end = BudgetPeriodUtils.computeEndDate(start, BudgetPeriod.CUSTOM);
      expect(end, start);
    });
  });
}
