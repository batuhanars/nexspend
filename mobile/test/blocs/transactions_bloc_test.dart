import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/data/models/transaction_model.dart';
import 'package:wallet_app/data/repositories/transaction_repository.dart';
import 'package:wallet_app/presentation/transactions/bloc/transactions_bloc.dart';

class MockTransactionRepository extends Mock
    implements TransactionRepository {}

// Sabit test verisi
final _tx1 = TransactionModel(
  id: 'tx-1',
  amount: 150.0,
  type: TransactionType.EXPENSE,
  source: TransactionSource.MANUAL,
  date: DateTime(2026, 5, 1),
);
final _tx2 = TransactionModel(
  id: 'tx-2',
  amount: 3000.0,
  type: TransactionType.INCOME,
  source: TransactionSource.MANUAL,
  date: DateTime(2026, 5, 1),
);

final _loadedResult = (
  data: [_tx1, _tx2],
  total: 2,
  totalPages: 1,
);

final _summary = (income: 3000.0, expense: 150.0, net: 2850.0);

void main() {
  late MockTransactionRepository repo;

  setUp(() {
    repo = MockTransactionRepository();
  });

  TransactionsBloc buildBloc() =>
      TransactionsBloc(transactionRepository: repo);

  group('TransactionsLoadRequested', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'başarılı yüklemede Loading → Loaded döner',
      build: () {
        when(() => repo.getTransactions(type: any(named: 'type'), limit: any(named: 'limit')))
            .thenAnswer((_) async => _loadedResult);
        when(() => repo.getSummary()).thenAnswer((_) async => _summary);
        return buildBloc();
      },
      act: (bloc) => bloc.add(TransactionsLoadRequested()),
      expect: () => [
        isA<TransactionsLoading>(),
        isA<TransactionsLoaded>()
            .having((s) => s.transactions.length, 'işlem sayısı', 2)
            .having((s) => s.income, 'gelir', 3000.0)
            .having((s) => s.expense, 'gider', 150.0)
            .having((s) => s.net, 'net', 2850.0),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'hata durumunda Loading → Error döner',
      build: () {
        when(() => repo.getTransactions(type: any(named: 'type'), limit: any(named: 'limit')))
            .thenThrow(Exception('network error'));
        when(() => repo.getSummary()).thenThrow(Exception('network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(TransactionsLoadRequested()),
      expect: () => [
        isA<TransactionsLoading>(),
        isA<TransactionsError>(),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'SocketException → Türkçe bağlantı hatası mesajı',
      build: () {
        when(() => repo.getTransactions(type: any(named: 'type'), limit: any(named: 'limit')))
            .thenThrow(Exception('SocketException'));
        when(() => repo.getSummary()).thenThrow(Exception('SocketException'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(TransactionsLoadRequested()),
      expect: () => [
        isA<TransactionsLoading>(),
        isA<TransactionsError>()
            .having((s) => s.message, 'mesaj', contains('İnternet')),
      ],
    );
  });

  group('TransactionsFilterChanged', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'filter=INCOME ile yüklemede filtreli Loaded döner',
      build: () {
        when(() => repo.getTransactions(type: 'INCOME', limit: any(named: 'limit')))
            .thenAnswer((_) async => (data: [_tx2], total: 1, totalPages: 1));
        when(() => repo.getSummary()).thenAnswer((_) async => _summary);
        return buildBloc();
      },
      act: (bloc) => bloc.add(TransactionsFilterChanged('INCOME')),
      expect: () => [
        isA<TransactionsLoaded>()
            .having((s) => s.filter, 'filter', 'INCOME')
            .having((s) => s.transactions.length, 'işlem sayısı', 1),
      ],
    );
  });

  group('TransactionDeleteRequested', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'başarılı silinmede optimistik güncelleme + yeniden yükleme',
      build: () {
        when(() => repo.getTransactions(type: any(named: 'type'), limit: any(named: 'limit')))
            .thenAnswer((_) async => _loadedResult);
        when(() => repo.getSummary()).thenAnswer((_) async => _summary);
        when(() => repo.deleteTransaction('tx-1')).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => TransactionsLoaded(
        transactions: [_tx1, _tx2],
        income: 3000.0,
        expense: 150.0,
        net: 2850.0,
        filter: null,
      ),
      act: (bloc) => bloc.add(TransactionDeleteRequested('tx-1')),
      expect: () => [
        // Optimistik güncelleme: tx-1 listeden çıkar
        isA<TransactionsLoaded>()
            .having((s) => s.transactions.length, 'optimistik', 1),
        // Yeniden yükleme sonrası (mock hâlâ 2 döndürüyor)
        isA<TransactionsLoaded>()
            .having((s) => s.transactions.length, 'yenileme', 2),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'silme API başarısız olursa eski state geri gelir',
      build: () {
        when(() => repo.deleteTransaction('tx-1'))
            .thenThrow(Exception('server error'));
        return buildBloc();
      },
      seed: () => TransactionsLoaded(
        transactions: [_tx1, _tx2],
        income: 3000.0,
        expense: 150.0,
        net: 2850.0,
        filter: null,
      ),
      act: (bloc) => bloc.add(TransactionDeleteRequested('tx-1')),
      expect: () => [
        // Optimistik güncelleme
        isA<TransactionsLoaded>()
            .having((s) => s.transactions.length, 'optimistik', 1),
        // Rollback: 2 işlem geri gelir
        isA<TransactionsLoaded>()
            .having((s) => s.transactions.length, 'rollback', 2),
      ],
    );
  });

  group('TransactionsRefreshRequested', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'yenileme başarılı olduğunda Loaded döner',
      build: () {
        when(() => repo.getTransactions(type: any(named: 'type'), limit: any(named: 'limit')))
            .thenAnswer((_) async => _loadedResult);
        when(() => repo.getSummary()).thenAnswer((_) async => _summary);
        return buildBloc();
      },
      act: (bloc) => bloc.add(TransactionsRefreshRequested()),
      expect: () => [isA<TransactionsLoaded>()],
    );
  });
}
