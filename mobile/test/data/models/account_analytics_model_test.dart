import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/data/models/account_analytics_model.dart';

void main() {
  group('MonthlyFlowModel.fromJson', () {
    test('standart hesap — income/expense parse edilir', () {
      final json = {
        'month': '2026-05',
        'income': 3000.0,
        'expense': 1500.0,
      };
      final model = MonthlyFlowModel.fromJson(json);
      expect(model.month, '2026-05');
      expect(model.income, 3000.0);
      expect(model.expense, 1500.0);
      expect(model.payment, isNull);
      expect(model.spend, isNull);
    });

    test('kredi kartı — payment/spend parse edilir', () {
      final json = {
        'month': '2026-05',
        'payment': 2000.0,
        'spend': 1800.0,
      };
      final model = MonthlyFlowModel.fromJson(json);
      expect(model.income, 0.0);
      expect(model.expense, 0.0);
      expect(model.payment, 2000.0);
      expect(model.spend, 1800.0);
    });
  });

  group('AccountAnalyticsModel.fromJson', () {
    test('isCreditCard=false — standart hesap getters doğru', () {
      final json = {
        'isCreditCard': false,
        'months': [
          {'month': '2026-04', 'income': 1000.0, 'expense': 600.0},
          {'month': '2026-05', 'income': 2000.0, 'expense': 900.0},
        ],
        'topCategories': [],
      };
      final model = AccountAnalyticsModel.fromJson(json);
      expect(model.isCreditCard, isFalse);
      expect(model.currentMonthIncome, 2000.0);
      expect(model.currentMonthExpense, 900.0);
      expect(model.currentMonthPayment, 0.0);
      expect(model.currentMonthSpend, 0.0);
    });

    test('isCreditCard=true — kredi kartı getters doğru', () {
      final json = {
        'isCreditCard': true,
        'months': [
          {'month': '2026-04', 'payment': 500.0, 'spend': 400.0},
          {'month': '2026-05', 'payment': 1200.0, 'spend': 950.0},
        ],
        'topCategories': [],
      };
      final model = AccountAnalyticsModel.fromJson(json);
      expect(model.isCreditCard, isTrue);
      expect(model.currentMonthPayment, 1200.0);
      expect(model.currentMonthSpend, 950.0);
      expect(model.currentMonthIncome, 0.0);
      expect(model.currentMonthExpense, 0.0);
    });

    test('isCreditCard alanı yoksa false default', () {
      final json = {
        'months': [],
        'topCategories': [],
      };
      final model = AccountAnalyticsModel.fromJson(json);
      expect(model.isCreditCard, isFalse);
    });
  });

  group('AccountAnalyticsModel.empty', () {
    test('empty() isCreditCard=false döner', () {
      final model = AccountAnalyticsModel.empty();
      expect(model.isCreditCard, isFalse);
      expect(model.months, isEmpty);
      expect(model.currentMonthPayment, 0.0);
      expect(model.currentMonthSpend, 0.0);
    });
  });
}
