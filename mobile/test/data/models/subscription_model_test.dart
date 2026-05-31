import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/data/models/subscription_model.dart';

void main() {
  group('SubscriptionModel.fromJson', () {
    test('kind ve reminderDaysBefore alanlarını parse eder', () {
      final model = SubscriptionModel.fromJson({
        'id': 'sub-1',
        'name': 'Elektrik',
        'amount': 300,
        'period': 'MONTHLY',
        'isActive': true,
        'autoDeduct': false,
        'kind': 'BILL',
        'reminderDaysBefore': 7,
        'nextRenewal': '2026-06-15',
      });

      expect(model.kind, SubscriptionKind.BILL);
      expect(model.isBill, isTrue);
      expect(model.reminderDaysBefore, 7);
      expect(model.nextRenewalDate, isNotNull);
    });

    test('eksik kind/reminder alanlarında güvenli default kullanır', () {
      final model = SubscriptionModel.fromJson({
        'id': 'sub-2',
        'name': 'Netflix',
        'amount': 149.99,
        'period': 'MONTHLY',
        'isActive': true,
        'autoDeduct': true,
      });

      expect(model.kind, SubscriptionKind.SUBSCRIPTION);
      expect(model.isBill, isFalse);
      expect(model.reminderDaysBefore, 3);
    });
  });
}
