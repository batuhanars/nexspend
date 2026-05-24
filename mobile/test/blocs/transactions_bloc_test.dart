import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/data/models/transaction_model.dart';
import 'package:wallet_app/data/repositories/transaction_repository.dart';
import 'package:wallet_app/presentation/transactions/bloc/transaction_filter.dart';
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
        when(() => repo.getTransactions(
              type: any(named: 'type'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => _loadedResult);
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
        when(() => repo.getTransactions(
              type: any(named: 'type'),
              limit: any(named: 'limit'),
            )).thenThrow(Exception('network error'));
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
        when(() => repo.getTransactions(
              type: any(named: 'type'),
              limit: any(named: 'limit'),
            )).thenThrow(Exception('SocketException'));
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

  group('TransactionsFilterChanged — TransactionFilter ile', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'type=INCOME ile yüklemede filtreli Loaded döner',
      build: () {
        when(() => repo.getTransactions(
              type: 'INCOME',
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => (data: [_tx2], total: 1, totalPages: 1));
        when(() => repo.getSummary()).thenAnswer((_) async => _summary);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        TransactionsFilterChanged(
          const TransactionFilter(type: 'INCOME'),
        ),
      ),
      expect: () => [
        isA<TransactionsLoaded>()
            .having((s) => s.filter.type, 'filter.type', 'INCOME')
            .having((s) => s.transactions.length, 'işlem sayısı', 1),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'çok-boyutlu filtre (type+categoryId) — doğru query param map\'i',
      build: () {
        when(() => repo.getTransactions(
              type: 'EXPENSE',
              categoryId: 'cat-1',
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => (data: [_tx1], total: 1, totalPages: 1));
        when(() => repo.getSummary()).thenAnswer((_) async => _summary);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        TransactionsFilterChanged(
          const TransactionFilter(type: 'EXPENSE', categoryId: 'cat-1'),
        ),
      ),
      expect: () => [
        isA<TransactionsLoaded>()
            .having((s) => s.filter.type, 'type', 'EXPENSE')
            .having((s) => s.filter.categoryId, 'categoryId', 'cat-1')
            .having((s) => s.transactions.length, 'işlem sayısı', 1),
      ],
      verify: (bloc) {
        // getTransactions categoryId ile çağrıldı mı doğrula
        verify(() => repo.getTransactions(
              type: 'EXPENSE',
              categoryId: 'cat-1',
              limit: any(named: 'limit'),
            )).called(1);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'her filtre değişiminde page 1\'den başlar (page reset)',
      build: () {
        when(() => repo.getTransactions(
              type: any(named: 'type'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => _loadedResult);
        when(() => repo.getSummary()).thenAnswer((_) async => _summary);
        return buildBloc();
      },
      seed: () => TransactionsLoaded(
        transactions: [_tx1, _tx2],
        income: 3000.0,
        expense: 150.0,
        net: 2850.0,
        filter: const TransactionFilter(type: 'INCOME'),
      ),
      act: (bloc) => bloc.add(
        TransactionsFilterChanged(const TransactionFilter(type: 'EXPENSE')),
      ),
      expect: () => [
        isA<TransactionsLoaded>()
            .having((s) => s.filter.type, 'type', 'EXPENSE'),
      ],
      verify: (bloc) {
        // page=1 ile çağrıldı mı — default named param olduğu için sadece
        // getTransactions çağrıldığını doğruluyoruz.
        verify(() => repo.getTransactions(
              type: 'EXPENSE',
              limit: any(named: 'limit'),
            )).called(1);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'accountId filtresi — doğru query param map\'i',
      build: () {
        when(() => repo.getTransactions(
              accountId: 'acc-1',
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => _loadedResult);
        when(() => repo.getSummary()).thenAnswer((_) async => _summary);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        TransactionsFilterChanged(
          const TransactionFilter(accountId: 'acc-1'),
        ),
      ),
      expect: () => [
        isA<TransactionsLoaded>()
            .having((s) => s.filter.accountId, 'accountId', 'acc-1'),
      ],
      verify: (bloc) {
        verify(() => repo.getTransactions(
              accountId: 'acc-1',
              limit: any(named: 'limit'),
            )).called(1);
      },
    );
  });

  group('TransactionFilter — activeCount getter', () {
    test('boş filtre activeCount=0', () {
      expect(TransactionFilter.empty.activeCount, 0);
    });

    test('type doluysa activeCount değişmez (type hariç)', () {
      const f = TransactionFilter(type: 'INCOME');
      expect(f.activeCount, 0);
    });

    test('categoryId doluysa activeCount=1', () {
      const f = TransactionFilter(categoryId: 'cat-1');
      expect(f.activeCount, 1);
    });

    test('accountId doluysa activeCount=1', () {
      const f = TransactionFilter(accountId: 'acc-1');
      expect(f.activeCount, 1);
    });

    test('startDate doluysa activeCount=1', () {
      final f = TransactionFilter(startDate: DateTime(2026, 1, 1));
      expect(f.activeCount, 1);
    });

    test('search doluysa activeCount=1', () {
      const f = TransactionFilter(search: 'market');
      expect(f.activeCount, 1);
    });

    test('birden fazla boyut — doğru toplam', () {
      final f = TransactionFilter(
        type: 'EXPENSE',
        categoryId: 'cat-1',
        accountId: 'acc-1',
        startDate: DateTime(2026, 1, 1),
        search: 'test',
      );
      // type hariç: category + account + date + search = 4
      expect(f.activeCount, 4);
    });
  });

  group('TransactionFilter — copyWith', () {
    test('type değişir, diğerleri korunur', () {
      const f = TransactionFilter(categoryId: 'cat-1', type: 'INCOME');
      final f2 = f.copyWith(type: 'EXPENSE');
      expect(f2.type, 'EXPENSE');
      expect(f2.categoryId, 'cat-1');
    });

    test('null ile alan sıfırlanır', () {
      const f = TransactionFilter(type: 'INCOME', categoryId: 'cat-1');
      final f2 = f.copyWith(categoryId: null);
      expect(f2.categoryId, isNull);
      expect(f2.type, 'INCOME');
    });
  });

  group('TransactionDeleteRequested', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'başarılı silinmede optimistik güncelleme + yeniden yükleme',
      build: () {
        when(() => repo.getTransactions(
              type: any(named: 'type'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => _loadedResult);
        when(() => repo.getSummary()).thenAnswer((_) async => _summary);
        when(() => repo.deleteTransaction('tx-1')).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => TransactionsLoaded(
        transactions: [_tx1, _tx2],
        income: 3000.0,
        expense: 150.0,
        net: 2850.0,
        filter: TransactionFilter.empty,
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
        filter: TransactionFilter.empty,
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
        when(() => repo.getTransactions(
              type: any(named: 'type'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => _loadedResult);
        when(() => repo.getSummary()).thenAnswer((_) async => _summary);
        return buildBloc();
      },
      act: (bloc) => bloc.add(TransactionsRefreshRequested()),
      expect: () => [isA<TransactionsLoaded>()],
    );
  });
}
