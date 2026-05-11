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

final _suggestion1 = const InflationSuggestionModel(
  budgetId: 'b-1',
  currentAmount: 3000.0,
  suggestedAmount: 3372.0,
  cumulativeRate: 12.4,
  monthsSinceUpdate: 3,
  categoryKey: 'gida',
);

final _comparison = InflationComparisonModel(
  period: '2026-04',
  rows: [
    const InflationComparisonRowModel(
      categoryId: 'cat-1',
      categoryName: 'Market',
      lastPeriodSpent: 2800.0,
      currentPeriodSpent: 3100.0,
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

final _history = <String, List<InflationRateModel>>{
  'genel': [
    InflationRateModel(
      categoryKey: 'genel',
      year: 2026,
      month: 2,
      monthlyRate: 2.1,
      fetchedAt: DateTime(2026, 3, 5),
    ),
    InflationRateModel(
      categoryKey: 'genel',
      year: 2026,
      month: 3,
      monthlyRate: 2.3,
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
  amount: 3372.0,
  spent: 1500.0,
  remaining: 1872.0,
  percentage: 45,
  status: BudgetStatus.OK,
  period: BudgetPeriod.MONTHLY,
  smartTracking: true,
  isActive: true,
  startDate: DateTime(2026, 2, 1),
);

void main() {
  late MockInflationRepository repo;

  setUp(() => repo = MockInflationRepository());

  InflationBloc buildBloc() =>
      InflationBloc(inflationRepository: repo);

  group('InflationSuggestionsFetchRequested', () {
    blocTest<InflationBloc, InflationState>(
      'boş liste → Loading olmadan Loaded emitler',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const InflationSuggestionsFetchRequested(budgetIds: []),
      ),
      expect: () => [
        isA<InflationSuggestionsLoaded>()
            .having((s) => s.suggestions.isEmpty, 'boş', true),
      ],
    );

    blocTest<InflationBloc, InflationState>(
      'başarılı fetch → Loading → Loaded (suggestion dolu)',
      build: () {
        when(() => repo.getSuggestion('b-1'))
            .thenAnswer((_) async => _suggestion1);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const InflationSuggestionsFetchRequested(budgetIds: ['b-1']),
      ),
      expect: () => [
        isA<InflationSuggestionsLoading>(),
        isA<InflationSuggestionsLoaded>()
            .having((s) => s.suggestions['b-1'], 'öneri', _suggestion1)
            .having((s) => s.suggestions.length, 'adet', 1),
      ],
    );

    blocTest<InflationBloc, InflationState>(
      '204 (null) döndüğünde suggestion map\'te null olur',
      build: () {
        when(() => repo.getSuggestion('b-1'))
            .thenAnswer((_) async => null);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const InflationSuggestionsFetchRequested(budgetIds: ['b-1']),
      ),
      expect: () => [
        isA<InflationSuggestionsLoading>(),
        isA<InflationSuggestionsLoaded>()
            .having((s) => s.suggestions['b-1'], '204 → null', isNull),
      ],
    );

    blocTest<InflationBloc, InflationState>(
      'hata durumunda Loading → Error emitler',
      build: () {
        when(() => repo.getSuggestion('b-1'))
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
      'başarılı apply → Applying → Applied emitler',
      build: () {
        when(() => repo.applyInflation('b-1', 3372.0))
            .thenAnswer((_) async => _updatedBudget);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const InflationApplyRequested(budgetId: 'b-1', newAmount: 3372.0),
      ),
      expect: () => [
        isA<InflationApplying>()
            .having((s) => s.budgetId, 'bütçe ID', 'b-1'),
        isA<InflationApplied>()
            .having((s) => s.budgetId, 'bütçe ID', 'b-1'),
      ],
    );

    blocTest<InflationBloc, InflationState>(
      'API hatası → Applying → ApplyError emitler',
      build: () {
        when(() => repo.applyInflation('b-1', 3372.0))
            .thenThrow(Exception('400 invalid amount'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const InflationApplyRequested(budgetId: 'b-1', newAmount: 3372.0),
      ),
      expect: () => [
        isA<InflationApplying>(),
        isA<InflationApplyError>(),
      ],
    );
  });

  group('InflationReportFetchRequested', () {
    blocTest<InflationBloc, InflationState>(
      'başarılı fetch → ReportLoading → ReportLoaded emitler',
      build: () {
        when(() => repo.getComparison(period: any(named: 'period')))
            .thenAnswer((_) async => _comparison);
        when(() => repo.getHistory(months: any(named: 'months')))
            .thenAnswer((_) async => _history);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const InflationReportFetchRequested(months: 3)),
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
              'genel verisi var',
              true,
            ),
      ],
    );

    blocTest<InflationBloc, InflationState>(
      'hata durumunda ReportLoading → ReportError emitler',
      build: () {
        when(() => repo.getComparison(period: any(named: 'period')))
            .thenThrow(Exception('server error'));
        when(() => repo.getHistory(months: any(named: 'months')))
            .thenThrow(Exception('server error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const InflationReportFetchRequested()),
      expect: () => [
        isA<InflationReportLoading>(),
        isA<InflationReportError>(),
      ],
    );
  });
}
