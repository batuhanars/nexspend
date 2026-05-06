import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/data/models/budget_model.dart';
import 'package:wallet_app/data/repositories/budget_repository.dart';
import 'package:wallet_app/presentation/budgets/bloc/budgets_bloc.dart';
import 'package:wallet_app/presentation/budgets/bloc/budgets_event.dart';
import 'package:wallet_app/presentation/budgets/bloc/budgets_state.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

final _overview = const BudgetOverviewModel(
  totalBudget: 10000.0,
  totalSpent: 4500.0,
  remaining: 5500.0,
  percentage: 45,
  count: 2,
);

final _budget1 = BudgetModel(
  id: 'b-1',
  name: 'Market',
  amount: 3000.0,
  spent: 1500.0,
  remaining: 1500.0,
  percentage: 50,
  status: BudgetStatus.WARNING,
  period: BudgetPeriod.MONTHLY,
  smartTracking: true,
  isActive: true,
  startDate: DateTime(2026, 5, 1),
);

final _budget2 = BudgetModel(
  id: 'b-2',
  name: 'Ulaşım',
  amount: 7000.0,
  spent: 3000.0,
  remaining: 4000.0,
  percentage: 43,
  status: BudgetStatus.OK,
  period: BudgetPeriod.MONTHLY,
  smartTracking: false,
  isActive: true,
  startDate: DateTime(2026, 5, 1),
);

void main() {
  late MockBudgetRepository repo;

  setUp(() => repo = MockBudgetRepository());

  BudgetsBloc buildBloc() => BudgetsBloc(budgetRepository: repo);

  void stubSuccess() {
    when(() => repo.getOverview()).thenAnswer((_) async => _overview);
    when(() => repo.getAll()).thenAnswer((_) async => [_budget1, _budget2]);
  }

  group('BudgetsLoadRequested', () {
    blocTest<BudgetsBloc, BudgetsState>(
      'başarılı yüklemede Loading → Loaded döner',
      build: () {
        stubSuccess();
        return buildBloc();
      },
      act: (bloc) => bloc.add(const BudgetsLoadRequested()),
      expect: () => [
        isA<BudgetsLoading>(),
        isA<BudgetsLoaded>()
            .having((s) => s.budgets.length, 'bütçe sayısı', 2)
            .having((s) => s.overview.totalBudget, 'toplam bütçe', 10000.0)
            .having((s) => s.overview.percentage, 'yüzde', 45),
      ],
    );

    blocTest<BudgetsBloc, BudgetsState>(
      'hata durumunda Loading → Error döner',
      build: () {
        when(() => repo.getOverview()).thenThrow(Exception('network error'));
        when(() => repo.getAll()).thenThrow(Exception('network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const BudgetsLoadRequested()),
      expect: () => [
        isA<BudgetsLoading>(),
        isA<BudgetsError>()
            .having((s) => s.message, 'mesaj', contains('yüklenemedi')),
      ],
    );
  });

  group('BudgetDeleteRequested', () {
    blocTest<BudgetsBloc, BudgetsState>(
      'başarılı silinmede bütçe listeden çıkar ve özet güncellenir',
      build: () {
        when(() => repo.delete('b-1')).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => BudgetsLoaded(overview: _overview, budgets: [_budget1, _budget2]),
      act: (bloc) => bloc.add(BudgetDeleteRequested('b-1')),
      expect: () => [
        isA<BudgetsLoaded>()
            .having((s) => s.budgets.length, 'bütçe sayısı', 1)
            .having((s) => s.budgets.first.id, 'kalan bütçe', 'b-2')
            .having((s) => s.overview.count, 'özet count', 1)
            .having((s) => s.overview.totalBudget, 'toplam bütçe', 7000.0),
      ],
    );

    blocTest<BudgetsBloc, BudgetsState>(
      'silme API başarısız olursa state değişmez',
      build: () {
        when(() => repo.delete('b-1'))
            .thenThrow(Exception('server error'));
        return buildBloc();
      },
      seed: () => BudgetsLoaded(overview: _overview, budgets: [_budget1, _budget2]),
      act: (bloc) => bloc.add(BudgetDeleteRequested('b-1')),
      expect: () => [],
    );
  });

  group('BudgetUpdateRequested', () {
    blocTest<BudgetsBloc, BudgetsState>(
      'güncelleme başarılı olduğunda optimistic emit sonra liste yenilenir',
      build: () {
        when(() => repo.update('b-1', any())).thenAnswer((_) async => _budget1);
        stubSuccess();
        return buildBloc();
      },
      seed: () => BudgetsLoaded(overview: _overview, budgets: [_budget1, _budget2]),
      act: (bloc) => bloc.add(BudgetUpdateRequested(id: 'b-1', data: {'amount': 3500})),
      expect: () => [
        isA<BudgetsLoaded>().having((s) => s.budgets.length, 'optimistic', 2),
        isA<BudgetsLoaded>().having((s) => s.budgets.length, 'yenileme', 2),
      ],
    );

    blocTest<BudgetsBloc, BudgetsState>(
      'güncelleme API başarısız olursa optimistic emit sonra orijinal state geri yüklenir',
      build: () {
        when(() => repo.update('b-1', any()))
            .thenThrow(Exception('server error'));
        return buildBloc();
      },
      seed: () => BudgetsLoaded(overview: _overview, budgets: [_budget1, _budget2]),
      act: (bloc) => bloc.add(BudgetUpdateRequested(id: 'b-1', data: {'amount': 3500})),
      expect: () => [
        isA<BudgetsLoaded>().having((s) => s.budgets.length, 'optimistic', 2),
        isA<BudgetsLoaded>().having((s) => s.budgets.length, 'revert', 2),
      ],
    );
  });

  group('BudgetsRefreshRequested', () {
    blocTest<BudgetsBloc, BudgetsState>(
      'yenileme başarılı olduğunda Loaded döner (Loading emitlemez)',
      build: () {
        stubSuccess();
        return buildBloc();
      },
      act: (bloc) => bloc.add(const BudgetsRefreshRequested()),
      expect: () => [isA<BudgetsLoaded>()],
    );
  });
}
