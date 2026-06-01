import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/data/models/subscription_model.dart';

void main() {
  group('SubscriptionModel.fromJson', () {
    test('reminderDaysBefore alanını parse eder', () {
      final model = SubscriptionModel.fromJson({
        'id': 'sub-1',
        'name': 'Netflix',
        'amount': 149.99,
        'period': 'MONTHLY',
        'isActive': true,
        'autoDeduct': true,
        'reminderDaysBefore': 7,
        'nextRenewal': '2026-06-15',
      });

      expect(model.reminderDaysBefore, 7);
      expect(model.nextRenewalDate, isNotNull);
    });

    test('eksik reminder alanında güvenli default kullanır', () {
      final model = SubscriptionModel.fromJson({
        'id': 'sub-2',
        'name': 'Spotify',
        'amount': 49.99,
        'period': 'MONTHLY',
        'isActive': true,
        'autoDeduct': true,
      });

      expect(model.reminderDaysBefore, 3);
    });

    test('billingCycle YEARLY olarak parse edilir', () {
      final model = SubscriptionModel.fromJson({
        'id': 'sub-3',
        'name': 'YouTube Premium',
        'amount': 599.99,
        'period': 'YEARLY',
        'isActive': true,
        'autoDeduct': true,
      });

      expect(model.billingCycle, BillingCycle.YEARLY);
    });
  });
}
