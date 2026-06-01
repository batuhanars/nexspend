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

final _subscription = const SubscriptionModel(
  id: 'sub-1',
  name: 'Netflix',
  amount: 149.99,
  billingCycle: BillingCycle.MONTHLY,
  isActive: true,
  autoDeduct: true,
  reminderDaysBefore: 3,
);

void main() {
  late MockSubscriptionRepository repo;

  setUp(() => repo = MockSubscriptionRepository());

  SubscriptionsBloc buildBloc() =>
      SubscriptionsBloc(subscriptionRepository: repo);

  void stubFetch() {
    when(() => repo.getAll()).thenAnswer((_) async => [_subscription]);
    when(() => repo.getSummary()).thenAnswer((_) async => _summary);
  }

  group('SubscriptionsLoadRequested', () {
    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'yükleme sonrası SubscriptionsLoaded emit edilir',
      build: () {
        stubFetch();
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SubscriptionsLoadRequested()),
      expect: () => [isA<SubscriptionsLoading>(), isA<SubscriptionsLoaded>()],
      verify: (_) {
        verify(() => repo.getAll()).called(1);
        verify(() => repo.getSummary()).called(1);
      },
    );
  });
}
