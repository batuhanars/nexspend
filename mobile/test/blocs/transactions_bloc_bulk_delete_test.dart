import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:wallet_app/data/models/transaction_model.dart';
import 'package:wallet_app/data/repositories/transaction_repository.dart';
import 'package:wallet_app/presentation/transactions/bloc/transaction_filter.dart';
import 'package:wallet_app/presentation/transactions/bloc/transactions_bloc.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

// Yardımcı: basit bir MANUAL TransactionModel oluşturur
TransactionModel _manual(String id) => TransactionModel(
      id: id,
      amount: 100,
      type: TransactionType.EXPENSE,
      source: TransactionSource.MANUAL,
      date: DateTime(2026, 5, 1),
    );

TransactionModel _auto(String id) => TransactionModel(
      id: id,
      amount: 50,
      type: TransactionType.EXPENSE,
      source: TransactionSource.RECURRING,
      date: DateTime(2026, 5, 2),
    );

TransactionsLoaded _loadedState({
  List<TransactionModel>? transactions,
  bool selectionMode = false,
  Set<String>? selectedIds,
}) =>
    TransactionsLoaded(
      transactions: transactions ??
          [_manual('m1'), _manual('m2'), _auto('a1')],
      income: 0,
      expense: 300,
      net: -300,
      filter: TransactionFilter.empty,
      selectionMode: selectionMode,
      selectedIds: selectedIds,
    );

void main() {
  late MockTransactionRepository repo;

  setUp(() {
    repo = MockTransactionRepository();
  });

  group('SelectionModeEntered', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'MANUAL id ile seçim modu açılır ve o id seçili olur',
      build: () => TransactionsBloc(transactionRepository: repo),
      seed: () => _loadedState(),
      act: (bloc) => bloc.add(SelectionModeEntered(initialId: 'm1')),
      expect: () => [
        isA<TransactionsLoaded>()
            .having((s) => s.selectionMode, 'selectionMode', true)
            .having((s) => s.selectedIds, 'selectedIds', {'m1'}),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'Otomatik id ile seçim modu açılır ama seçim boş kalır',
      build: () => TransactionsBloc(transactionRepository: repo),
      seed: () => _loadedState(),
      act: (bloc) => bloc.add(SelectionModeEntered(initialId: 'a1')),
      expect: () => [
        isA<TransactionsLoaded>()
            .having((s) => s.selectionMode, 'selectionMode', true)
            .having((s) => s.selectedIds, 'selectedIds', <String>{}),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'initialId olmadan seçim modu açılır, seçim boş',
      build: () => TransactionsBloc(transactionRepository: repo),
      seed: () => _loadedState(),
      act: (bloc) => bloc.add(SelectionModeEntered()),
      expect: () => [
        isA<TransactionsLoaded>()
            .having((s) => s.selectionMode, 'selectionMode', true)
            .having((s) => s.selectedIds, 'selectedIds', <String>{}),
      ],
    );
  });

  group('SelectionToggled', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'MANUAL id toggle ekler',
      build: () => TransactionsBloc(transactionRepository: repo),
      seed: () => _loadedState(selectionMode: true, selectedIds: {}),
      act: (bloc) => bloc.add(SelectionToggled('m1')),
      expect: () => [
        isA<TransactionsLoaded>()
            .having((s) => s.selectedIds, 'selectedIds', {'m1'}),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'MANUAL id zaten seçiliyse kaldırır',
      build: () => TransactionsBloc(transactionRepository: repo),
      seed: () => _loadedState(selectionMode: true, selectedIds: {'m1'}),
      act: (bloc) => bloc.add(SelectionToggled('m1')),
      expect: () => [
        isA<TransactionsLoaded>()
            .having((s) => s.selectedIds, 'selectedIds', <String>{}),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'Otomatik işlem toggle — no-op (state değişmez)',
      build: () => TransactionsBloc(transactionRepository: repo),
      seed: () => _loadedState(selectionMode: true, selectedIds: {}),
      act: (bloc) => bloc.add(SelectionToggled('a1')),
      expect: () => <TransactionsState>[], // no emit
    );
  });

  group('SelectionCleared', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'Seçim modu kapatılır ve selectedIds temizlenir',
      build: () => TransactionsBloc(transactionRepository: repo),
      seed: () => _loadedState(selectionMode: true, selectedIds: {'m1', 'm2'}),
      act: (bloc) => bloc.add(SelectionCleared()),
      expect: () => [
        isA<TransactionsLoaded>()
            .having((s) => s.selectionMode, 'selectionMode', false)
            .having((s) => s.selectedIds, 'selectedIds', <String>{}),
      ],
    );
  });

  group('BulkDeleteRequested', () {
    // Başarı: optimistic emit (kısaltılmış liste + mod kapalı) + sonra refresh
    blocTest<TransactionsBloc, TransactionsState>(
      'Başarı: önce optimistic emit, sonra refresh sonucu emit',
      build: () {
        when(() => repo.bulkDelete(any()))
            .thenAnswer((_) async => 2);
        // Refresh için getTransactions + getSummary mock
        when(() => repo.getTransactions(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => (
              data: <TransactionModel>[_auto('a1')],
              total: 1,
              totalPages: 1,
            ));
        when(() => repo.getSummary()).thenAnswer((_) async => (
              income: 0.0,
              expense: 50.0,
              net: -50.0,
            ));
        return TransactionsBloc(transactionRepository: repo);
      },
      seed: () => _loadedState(
        selectionMode: true,
        selectedIds: {'m1', 'm2'},
      ),
      act: (bloc) => bloc.add(BulkDeleteRequested()),
      expect: () => [
        // 1. Optimistic: m1 + m2 listeden çıkar, seçim modu kapanır
        isA<TransactionsLoaded>()
            .having((s) => s.selectionMode, 'selectionMode', false)
            .having((s) => s.selectedIds, 'selectedIds', <String>{})
            .having(
              (s) => s.transactions.map((t) => t.id).toList(),
              'transactions',
              ['a1'],
            ),
        // 2. Refresh sonucu (getSummary + getTransactions)
        isA<TransactionsLoaded>()
            .having((s) => s.selectionMode, 'selectionMode', false)
            .having(
              (s) => s.transactions.map((t) => t.id).toList(),
              'transactions',
              ['a1'],
            ),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'Hata: optimistic emit sonrası eski state\'e revert',
      build: () {
        when(() => repo.bulkDelete(any()))
            .thenThrow(Exception('Network error'));
        return TransactionsBloc(transactionRepository: repo);
      },
      seed: () => _loadedState(
        selectionMode: true,
        selectedIds: {'m1'},
      ),
      act: (bloc) => bloc.add(BulkDeleteRequested()),
      expect: () => [
        // 1. Optimistic
        isA<TransactionsLoaded>()
            .having((s) => s.selectionMode, 'selectionMode', false)
            .having(
              (s) => s.transactions.map((t) => t.id).toList(),
              'transactions',
              ['m2', 'a1'],
            ),
        // 2. Revert — orijinal state geri gelir
        isA<TransactionsLoaded>()
            .having((s) => s.selectionMode, 'selectionMode', true)
            .having(
              (s) => s.transactions.map((t) => t.id).toList(),
              'transactions',
              ['m1', 'm2', 'a1'],
            ),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'selectedIds boşsa hiçbir şey olmaz',
      build: () => TransactionsBloc(transactionRepository: repo),
      seed: () => _loadedState(selectionMode: true, selectedIds: {}),
      act: (bloc) => bloc.add(BulkDeleteRequested()),
      expect: () => <TransactionsState>[],
    );
  });
}
