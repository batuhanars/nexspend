import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/data/models/debt_model.dart';
import 'package:wallet_app/data/repositories/debt_repository.dart';
import 'package:wallet_app/presentation/debts/bloc/debts_bloc.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

final _summary = const DebtSummaryModel(
  totalLent: 5000.0,
  totalBorrowed: 2000.0,
  totalLentRemaining: 3000.0,
  totalBorrowedRemaining: 1500.0,
);

final _debt1 = const DebtModel(
  id: 'debt-1',
  type: DebtType.LENT,
  status: DebtStatus.PENDING,
  personName: 'Ahmet',
  totalAmount: 1000.0,
  paidAmount: 200.0,
  hasInstallments: false,
);

final _debt2 = const DebtModel(
  id: 'debt-2',
  type: DebtType.BORROWED,
  status: DebtStatus.OVERDUE,
  personName: 'Mehmet',
  totalAmount: 2000.0,
  paidAmount: 500.0,
  hasInstallments: true,
);

void main() {
  late MockDebtRepository repo;

  setUp(() => repo = MockDebtRepository());

  DebtsBloc buildBloc() => DebtsBloc(debtRepository: repo);

  void stubSuccess() {
    when(() => repo.getAll(type: any(named: 'type'), status: any(named: 'status')))
        .thenAnswer((_) async => [_debt1, _debt2]);
    when(() => repo.getSummary()).thenAnswer((_) async => _summary);
  }

  group('DebtsLoadRequested', () {
    blocTest<DebtsBloc, DebtsState>(
      'başarılı yüklemede Loading → Loaded döner',
      build: () {
        stubSuccess();
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DebtsLoadRequested()),
      expect: () => [
        isA<DebtsLoading>(),
        isA<DebtsLoaded>()
            .having((s) => s.debts.length, 'borç sayısı', 2)
            .having((s) => s.summary.totalLent, 'toplam alacak', 5000.0),
      ],
    );

    blocTest<DebtsBloc, DebtsState>(
      'hata durumunda Loading → Error döner',
      build: () {
        when(() => repo.getAll(type: any(named: 'type'), status: any(named: 'status')))
            .thenThrow(Exception('network error'));
        when(() => repo.getSummary()).thenThrow(Exception('network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DebtsLoadRequested()),
      expect: () => [
        isA<DebtsLoading>(),
        isA<DebtsError>(),
      ],
    );

    blocTest<DebtsBloc, DebtsState>(
      'SocketException → Türkçe bağlantı hatası mesajı',
      build: () {
        when(() => repo.getAll(type: any(named: 'type'), status: any(named: 'status')))
            .thenThrow(Exception('SocketException'));
        when(() => repo.getSummary()).thenThrow(Exception('SocketException'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DebtsLoadRequested()),
      expect: () => [
        isA<DebtsLoading>(),
        isA<DebtsError>()
            .having((s) => s.message, 'mesaj', contains('İnternet')),
      ],
    );
  });

  group('DebtsFilterChanged', () {
    blocTest<DebtsBloc, DebtsState>(
      'filter=LENT ile sadece alacaklar döner',
      build: () {
        when(() => repo.getAll(type: 'LENT', status: any(named: 'status')))
            .thenAnswer((_) async => [_debt1]);
        when(() => repo.getSummary()).thenAnswer((_) async => _summary);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DebtsFilterChanged('LENT')),
      expect: () => [
        isA<DebtsLoaded>()
            .having((s) => s.filter, 'filter', 'LENT')
            .having((s) => s.debts.length, 'borç sayısı', 1),
      ],
    );
  });

  group('DebtDeleteRequested', () {
    blocTest<DebtsBloc, DebtsState>(
      'başarılı silinmede optimistik güncelleme',
      build: () {
        when(() => repo.delete('debt-1')).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => DebtsLoaded(
        debts: [_debt1, _debt2],
        summary: _summary,
      ),
      act: (bloc) => bloc.add(const DebtDeleteRequested('debt-1')),
      expect: () => [
        isA<DebtsLoaded>()
            .having((s) => s.debts.length, 'optimistik güncelleme', 1)
            .having((s) => s.debts.first.id, 'kalan borç', 'debt-2'),
      ],
    );

    blocTest<DebtsBloc, DebtsState>(
      'silme API başarısız olursa eski state geri gelir',
      build: () {
        when(() => repo.delete('debt-1'))
            .thenThrow(Exception('server error'));
        return buildBloc();
      },
      seed: () => DebtsLoaded(
        debts: [_debt1, _debt2],
        summary: _summary,
      ),
      act: (bloc) => bloc.add(const DebtDeleteRequested('debt-1')),
      expect: () => [
        isA<DebtsLoaded>()
            .having((s) => s.debts.length, 'optimistik', 1),
        isA<DebtsLoaded>()
            .having((s) => s.debts.length, 'rollback', 2),
      ],
    );
  });

  group('DebtPaymentRecorded', () {
    blocTest<DebtsBloc, DebtsState>(
      'ödeme kaydedildikten sonra liste yenilenir',
      build: () {
        when(() => repo.recordPayment('debt-1', any())).thenAnswer((_) async {});
        stubSuccess();
        return buildBloc();
      },
      seed: () => DebtsLoaded(debts: [_debt1, _debt2], summary: _summary),
      act: (bloc) => bloc.add(
        const DebtPaymentRecorded(debtId: 'debt-1', data: {'amount': 300}),
      ),
      expect: () => [
        isA<DebtsLoaded>().having((s) => s.debts.length, 'yenileme', 2),
      ],
    );

    blocTest<DebtsBloc, DebtsState>(
      'ödeme API başarısız olursa Error döner',
      build: () {
        when(() => repo.recordPayment('debt-1', any()))
            .thenThrow(Exception('server error'));
        return buildBloc();
      },
      seed: () => DebtsLoaded(debts: [_debt1, _debt2], summary: _summary),
      act: (bloc) => bloc.add(
        const DebtPaymentRecorded(debtId: 'debt-1', data: {'amount': 300}),
      ),
      expect: () => [isA<DebtsError>()],
    );
  });

  group('DebtsRefreshRequested', () {
    blocTest<DebtsBloc, DebtsState>(
      'yenileme başarılı olduğunda Loaded döner (Loading emitlemez)',
      build: () {
        stubSuccess();
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DebtsRefreshRequested()),
      expect: () => [isA<DebtsLoaded>()],
    );
  });
}
