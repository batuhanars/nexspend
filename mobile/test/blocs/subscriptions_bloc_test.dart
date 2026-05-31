import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/data/models/subscription_model.dart';
import 'package:wallet_app/data/repositories/subscription_repository.dart';
import 'package:wallet_app/presentation/subscriptions/bloc/subscriptions_bloc.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

final _summary =
    const SubscriptionSummaryModel(totalMonthly: 300, activeCount: 1);

final _bill = const SubscriptionModel(
  id: 'sub-1',
  name: 'Elektrik',
  amount: 300,
  billingCycle: BillingCycle.MONTHLY,
  isActive: true,
  autoDeduct: false,
  kind: SubscriptionKind.BILL,
  reminderDaysBefore: 3,
);

void main() {
  late MockSubscriptionRepository repo;

  setUp(() => repo = MockSubscriptionRepository());

  SubscriptionsBloc buildBloc() =>
      SubscriptionsBloc(subscriptionRepository: repo);

  void stubFetch() {
    when(() => repo.getAll()).thenAnswer((_) async => [_bill]);
    when(() => repo.getSummary()).thenAnswer((_) async => _summary);
  }

  group('SubscriptionPayRequested', () {
    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'ödeme sonrası repo.pay çağrılır ve liste yeniden yüklenir',
      build: () {
        stubFetch();
        when(() => repo.pay(any(), any()))
            .thenAnswer((_) async => _bill);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const SubscriptionPayRequested(id: 'sub-1', amount: 427.5),
      ),
      expect: () => [isA<SubscriptionsLoaded>()],
      verify: (_) {
        verify(() => repo.pay('sub-1', {'amount': 427.5})).called(1);
        verify(() => repo.getAll()).called(1);
      },
    );

    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'ödeme başarısızsa Error döner',
      build: () {
        when(() => repo.pay(any(), any())).thenThrow(Exception('fail'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const SubscriptionPayRequested(id: 'sub-1', amount: 100),
      ),
      expect: () => [isA<SubscriptionsError>()],
    );
  });
}
