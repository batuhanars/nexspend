import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/data/models/insight_model.dart';
import 'package:wallet_app/data/repositories/insights_repository.dart';
import 'package:wallet_app/presentation/insights/bloc/insights_bloc.dart';
import 'package:wallet_app/presentation/insights/bloc/insights_event.dart';
import 'package:wallet_app/presentation/insights/bloc/insights_state.dart';

class MockInsightsRepository extends Mock implements InsightsRepository {}

final _insight1 = InsightModel(
  id: 'ins-1',
  ruleId: 'spending_spike',
  title: 'Market harcaman %42 arttı',
  message: 'Bu ay ₺882 fazla harcadın.',
  category: 'Market',
  severity: 'warning',
  data: null,
  isRead: false,
  isDismissed: false,
  period: '2026-04',
  createdAt: DateTime(2026, 5, 1),
);

final _insight2 = InsightModel(
  id: 'ins-2',
  ruleId: 'saving_streak',
  title: '3 ay üst üste tasarruf',
  message: 'Ortalama +₺1.250/ay',
  category: null,
  severity: 'success',
  data: null,
  isRead: true,
  isDismissed: false,
  period: '2026-04',
  createdAt: DateTime(2026, 5, 1),
);

final _summary = InsightSummaryModel(
  unreadCount: 2,
  totalCount: 3,
  latestInsight: _insight1,
);

final _generateResult = InsightGenerateResultModel(
  generated: 4,
  period: '2026-05',
);

void main() {
  late MockInsightsRepository repo;

  setUp(() => repo = MockInsightsRepository());

  InsightsBloc buildBloc() => InsightsBloc(insightsRepository: repo);

  group('InsightsFetchRequested', () {
    blocTest<InsightsBloc, InsightsState>(
      'başarılı fetch — Loading → Loaded',
      build: () {
        when(() => repo.getInsights(period: any(named: 'period')))
            .thenAnswer((_) async => [_insight1, _insight2]);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const InsightsFetchRequested(period: '2026-04')),
      expect: () => [
        isA<InsightsLoading>(),
        isA<InsightsLoaded>()
            .having((s) => s.insights.length, 'insight sayısı', 2)
            .having((s) => s.period, 'period', '2026-04'),
      ],
    );

    blocTest<InsightsBloc, InsightsState>(
      'boş liste — Loaded (boş)',
      build: () {
        when(() => repo.getInsights(period: any(named: 'period')))
            .thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const InsightsFetchRequested()),
      expect: () => [
        isA<InsightsLoading>(),
        isA<InsightsLoaded>()
            .having((s) => s.insights.isEmpty, 'boş', true),
      ],
    );

    blocTest<InsightsBloc, InsightsState>(
      'API hatası — Loading → Error',
      build: () {
        when(() => repo.getInsights(period: any(named: 'period')))
            .thenThrow(Exception('network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const InsightsFetchRequested()),
      expect: () => [
        isA<InsightsLoading>(),
        isA<InsightsError>(),
      ],
    );
  });

  group('InsightsSummaryFetchRequested', () {
    blocTest<InsightsBloc, InsightsState>(
      'başarılı summary fetch — Loading → Loaded',
      build: () {
        when(() => repo.getSummary()).thenAnswer((_) async => _summary);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const InsightsSummaryFetchRequested()),
      expect: () => [
        isA<InsightsSummaryLoading>(),
        isA<InsightsSummaryLoaded>()
            .having((s) => s.summary.unreadCount, 'unreadCount', 2)
            .having((s) => s.summary.totalCount, 'totalCount', 3),
      ],
    );

    blocTest<InsightsBloc, InsightsState>(
      'summary API hatası — Loading → Error',
      build: () {
        when(() => repo.getSummary()).thenThrow(Exception('500'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const InsightsSummaryFetchRequested()),
      expect: () => [
        isA<InsightsSummaryLoading>(),
        isA<InsightsSummaryError>(),
      ],
    );
  });

  group('InsightsDismissRequested', () {
    final dismissedInsight = InsightModel(
      id: 'ins-1',
      ruleId: 'spending_spike',
      title: 'Market harcaman %42 arttı',
      message: 'Bu ay ₺882 fazla harcadın.',
      category: 'Market',
      severity: 'warning',
      data: null,
      isRead: false,
      isDismissed: true,
      period: '2026-04',
      createdAt: DateTime(2026, 5, 1),
    );

    blocTest<InsightsBloc, InsightsState>(
      'dismiss — Dismissing → Dismissed → Loaded (kart listeden çıkar)',
      build: () {
        when(() => repo.getInsights(period: any(named: 'period')))
            .thenAnswer((_) async => [_insight1, _insight2]);
        when(() => repo.dismiss('ins-1'))
            .thenAnswer((_) async => dismissedInsight);
        return buildBloc();
      },
      seed: () => InsightsLoaded(insights: [_insight1, _insight2]),
      act: (bloc) =>
          bloc.add(const InsightsDismissRequested(insightId: 'ins-1')),
      expect: () => [
        isA<InsightDismissing>()
            .having((s) => s.insightId, 'insightId', 'ins-1'),
        isA<InsightDismissed>()
            .having((s) => s.insightId, 'dismissed id', 'ins-1')
            .having((s) => s.insights.length, 'kalan insight sayısı', 1),
        isA<InsightsLoaded>()
            .having((s) => s.insights.length, 'liste güncellendi', 1),
      ],
    );

    blocTest<InsightsBloc, InsightsState>(
      'dismiss API hatası — Dismissing → Error',
      build: () {
        when(() => repo.dismiss('ins-1'))
            .thenThrow(Exception('404 not found'));
        return buildBloc();
      },
      seed: () => InsightsLoaded(insights: [_insight1]),
      act: (bloc) =>
          bloc.add(const InsightsDismissRequested(insightId: 'ins-1')),
      expect: () => [
        isA<InsightDismissing>(),
        isA<InsightsError>()
            .having((s) => s.message, 'hata mesajı', contains('bulunamadı')),
      ],
    );
  });

  group('InsightsMarkReadRequested', () {
    final readInsight = InsightModel(
      id: 'ins-1',
      ruleId: 'spending_spike',
      title: 'Market harcaman %42 arttı',
      message: 'Bu ay ₺882 fazla harcadın.',
      category: 'Market',
      severity: 'warning',
      data: null,
      isRead: true,
      isDismissed: false,
      period: '2026-04',
      createdAt: DateTime(2026, 5, 1),
    );

    blocTest<InsightsBloc, InsightsState>(
      'mark read — ReadMarked → Loaded (isRead=true)',
      build: () {
        when(() => repo.markRead('ins-1'))
            .thenAnswer((_) async => readInsight);
        return buildBloc();
      },
      seed: () => InsightsLoaded(insights: [_insight1, _insight2]),
      act: (bloc) =>
          bloc.add(const InsightsMarkReadRequested(insightId: 'ins-1')),
      expect: () => [
        isA<InsightReadMarked>().having(
          (s) => s.insights.firstWhere((i) => i.id == 'ins-1').isRead,
          'okundu olarak işaretlendi',
          true,
        ),
        isA<InsightsLoaded>(),
      ],
    );

    blocTest<InsightsBloc, InsightsState>(
      'mark read API hatası — sessiz (state değişmez)',
      build: () {
        when(() => repo.markRead('ins-1')).thenThrow(Exception('500'));
        return buildBloc();
      },
      seed: () => InsightsLoaded(insights: [_insight1]),
      act: (bloc) =>
          bloc.add(const InsightsMarkReadRequested(insightId: 'ins-1')),
      expect: () => [],
    );
  });

  group('InsightsGenerateRequested', () {
    blocTest<InsightsBloc, InsightsState>(
      'generate — Generating → Generated',
      build: () {
        when(() => repo.generate()).thenAnswer((_) async => _generateResult);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const InsightsGenerateRequested()),
      expect: () => [
        isA<InsightsGenerating>(),
        isA<InsightsGenerated>()
            .having((s) => s.generated, 'üretilen insight sayısı', 4)
            .having((s) => s.period, 'period', '2026-05'),
      ],
    );

    blocTest<InsightsBloc, InsightsState>(
      'generate API hatası — Generating → Error',
      build: () {
        when(() => repo.generate()).thenThrow(Exception('server error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const InsightsGenerateRequested()),
      expect: () => [
        isA<InsightsGenerating>(),
        isA<InsightsGenerateError>(),
      ],
    );
  });
}
