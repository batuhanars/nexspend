import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/data/models/budget_model.dart';
import 'package:wallet_app/data/models/inflation_model.dart';
import 'package:wallet_app/data/repositories/inflation_repository.dart';
import 'package:wallet_app/presentation/inflation/bloc/inflation_bloc.dart';
import 'package:wallet_app/presentation/inflation/bloc/inflation_event.dart';
import 'package:wallet_app/presentation/inflation/bloc/inflation_state.dart';

class MockInflationRepository extends Mock implements InflationRepository {}

final _suggestion1 = InflationSuggestionModel(
  budgetId: 'b-1',
  currentAmount: 3000,
  suggestedAmount: 3372,
  cumulativeRate: 12.4,
  monthsSinceUpdate: 3,
  categoryKey: 'gida',
);

final _comparisonModel = InflationComparisonModel(
  period: '2026-04',
  rows: [
    InflationComparisonRowModel(
      categoryId: 'cat-1',
      categoryName: 'Market',
      lastPeriodSpent: 2800,
      currentPeriodSpent: 3100,
      userChangeRate: 10.71,
      inflationRate: 8.20,
      status: InflationComparisonStatus.ABOVE,
    ),
  ],
  summary: const InflationComparisonSummary(
    categoriesBelow: 0,
    categoriesAbove: 1,
    categoriesEqual: 0,
  ),
);

final _historyMap = <String, List<InflationRateModel>>{
  'genel': [
    InflationRateModel(
      categoryKey: 'genel',
      year: 2026,
      month: 3,
      monthlyRate: 2.1,
      fetchedAt: DateTime(2026, 4, 5),
    ),
    InflationRateModel(
      categoryKey: 'genel',
      year: 2026,
      month: 4,
      monthlyRate: 2.45,
      fetchedAt: DateTime(2026, 5, 5),
    ),
  ],
};

final _updatedBudget = BudgetModel(
  id: 'b-1',
  name: 'Market',
  amount: 3372,
  spent: 1500,
  remaining: 1872,
  percentage: 45,
  status: BudgetStatus.OK,
  period: BudgetPeriod.MONTHLY,
  smartTracking: true,
  isActive: true,
  startDate: DateTime(2026, 5, 1),
);

void main() {
  late MockInflationRepository repo;

  setUp(() => repo = MockInflationRepository());

  InflationBloc buildBloc() =>
      InflationBloc(inflationRepository: repo);

  group('InflationSuggestionsFetchRequested', () {
    blocTest<InflationBloc, InflationState>(
      'başarılı suggestion fetch — Loading → Loaded (öneri var)',
      build: () {
        when(() => repo.getSuggestion('b-1'))
            .thenAnswer((_) async => _suggestion1);
        when(() => repo.getSuggestion('b-2'))
            .thenAnswer((_) async => null); // 204
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const InflationSuggestionsFetchRequested(budgetIds: ['b-1', 'b-2']),
      ),
      expect: () => [
        isA<InflationSuggestionsLoading>(),
        isA<InflationSuggestionsLoaded>()
            .having(
              (s) => s.suggestions['b-1'],
              'b-1 öneri var',
              isA<InflationSuggestionModel>(),
            )
            .having(
              (s) => s.suggestions['b-2'],
              'b-2 öneri yok (204)',
              isNull,
            ),
      ],
    );

    blocTest<InflationBloc, InflationState>(
      'boş budgetIds listesi — Loaded (boş map, loading emit edilmez)',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(
        const InflationSuggestionsFetchRequested(budgetIds: []),
      ),
      expect: () => [
        isA<InflationSuggestionsLoaded>()
            .having((s) => s.suggestions.isEmpty, 'boş map', true),
      ],
    );

    blocTest<InflationBloc, InflationState>(
      'API hata durumunda Loading → Error',
      build: () {
        when(() => repo.getSuggestion(any()))
            .thenThrow(Exception('network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const InflationSuggestionsFetchRequested(budgetIds: ['b-1']),
      ),
      expect: () => [
        isA<InflationSuggestionsLoading>(),
        isA<InflationSuggestionsError>(),
      ],
    );
  });

  group('InflationApplyRequested', () {
    blocTest<InflationBloc, InflationState>(
      'başarılı apply — Applying → Applied',
      build: () {
        when(() => repo.applyInflation('b-1', 3372))
            .thenAnswer((_) async => _updatedBudget);
        return buildBloc();
      },
      seed: () => InflationSuggestionsLoaded(
          suggestions: {'b-1': _suggestion1}),
      act: (bloc) => bloc.add(
        const InflationApplyRequested(budgetId: 'b-1', newAmount: 3372),
      ),
      expect: () => [
        isA<InflationApplying>()
            .having((s) => s.budgetId, 'budgetId', 'b-1'),
        isA<InflationApplied>()
            .having((s) => s.budgetId, 'applied budgetId', 'b-1'),
      ],
    );

    blocTest<InflationBloc, InflationState>(
      'apply API başarısız — Applying → ApplyError',
      build: () {
        when(() => repo.applyInflation('b-1', any()))
            .thenThrow(Exception('400'));
        return buildBloc();
      },
      seed: () => InflationSuggestionsLoaded(
          suggestions: {'b-1': _suggestion1}),
      act: (bloc) => bloc.add(
        const InflationApplyRequested(budgetId: 'b-1', newAmount: 9999),
      ),
      expect: () => [
        isA<InflationApplying>(),
        isA<InflationApplyError>()
            .having((s) => s.message, 'hata mesajı', contains('yüklenemedi')),
      ],
    );
  });

  group('InflationReportFetchRequested', () {
    blocTest<InflationBloc, InflationState>(
      'başarılı reports fetch — Loading → Loaded',
      build: () {
        when(() => repo.getComparison(period: any(named: 'period')))
            .thenAnswer((_) async => _comparisonModel);
        when(() => repo.getHistory(months: any(named: 'months')))
            .thenAnswer((_) async => _historyMap);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const InflationReportFetchRequested(period: '2026-04'),
      ),
      expect: () => [
        isA<InflationReportLoading>(),
        isA<InflationReportLoaded>()
            .having(
              (s) => s.comparison.rows.length,
              'satır sayısı',
              1,
            )
            .having(
              (s) => s.history.containsKey('genel'),
              'genel history var',
              true,
            ),
      ],
    );

    blocTest<InflationBloc, InflationState>(
      'reports fetch API hata — Loading → Error',
      build: () {
        when(() => repo.getComparison(period: any(named: 'period')))
            .thenThrow(Exception('server error'));
        when(() => repo.getHistory(months: any(named: 'months')))
            .thenAnswer((_) async => {});
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const InflationReportFetchRequested()),
      expect: () => [
        isA<InflationReportLoading>(),
        isA<InflationReportError>(),
      ],
    );
  });
}
