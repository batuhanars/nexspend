import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import 'transaction_filter.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  TransactionsBloc({required TransactionRepository transactionRepository})
      : _repo = transactionRepository,
        super(TransactionsInitial()) {
    on<TransactionsLoadRequested>(_onLoad);
    on<TransactionsRefreshRequested>(_onRefresh);
    on<TransactionsLoadMoreRequested>(_onLoadMore);
    on<TransactionsFilterChanged>(_onFilterChanged);
    on<TransactionDeleteRequested>(_onDelete);
    on<SelectionModeEntered>(_onSelectionModeEntered);
    on<SelectionToggled>(_onSelectionToggled);
    on<SelectionCleared>(_onSelectionCleared);
    on<BulkDeleteRequested>(_onBulkDelete);
  }

  final TransactionRepository _repo;
  TransactionFilter _currentFilter = TransactionFilter.empty;
  int _currentPage = 1;
  static const int _pageSize = 20;

  Future<void> _onLoad(
    TransactionsLoadRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(TransactionsLoading());
    _currentPage = 1;
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    TransactionsRefreshRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    _currentPage = 1;
    await _fetch(emit);
  }

  Future<void> _onLoadMore(
    TransactionsLoadMoreRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    final current = state;
    if (current is! TransactionsLoaded || !current.hasMore || current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = _currentPage + 1;
      final txResult = await _repo.getTransactions(
        type: _currentFilter.type,
        categoryId: _currentFilter.categoryId,
        accountId: _currentFilter.accountId,
        startDate: _currentFilter.startDate?.toIso8601String().substring(0, 10),
        endDate: _currentFilter.endDate?.toIso8601String().substring(0, 10),
        search: _currentFilter.search,
        page: nextPage,
        limit: _pageSize,
      );
      _currentPage = nextPage;
      emit(current.copyWith(
        transactions: [...current.transactions, ...txResult.data],
        hasMore: nextPage < txResult.totalPages,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onFilterChanged(
    TransactionsFilterChanged event,
    Emitter<TransactionsState> emit,
  ) async {
    _currentFilter = event.filter;
    _currentPage = 1;
    await _fetch(emit);
  }

  Future<void> _onDelete(
    TransactionDeleteRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    final current = state;
    if (current is! TransactionsLoaded) return;

    // Optimistik: hemen listeden kaldır
    final updated = current.transactions
        .where((t) => t.id != event.id)
        .toList();
    emit(TransactionsLoaded(
      transactions: updated,
      income: current.income,
      expense: current.expense,
      net: current.net,
      filter: current.filter,
    ));

    try {
      await _repo.deleteTransaction(event.id);
      // Özeti yenile
      await _fetch(emit);
    } catch (_) {
      // Başarısız olursa önceki state'e dön
      emit(current);
    }
  }

  void _onSelectionModeEntered(
    SelectionModeEntered event,
    Emitter<TransactionsState> emit,
  ) {
    final current = state;
    if (current is! TransactionsLoaded) return;

    final ids = <String>{};
    if (event.initialId != null) {
      // Yalnız MANUAL işlemler seçilebilir
      final tx = current.transactions
          .where((t) => t.id == event.initialId)
          .firstOrNull;
      if (tx != null && tx.source == TransactionSource.MANUAL) {
        ids.add(event.initialId!);
      }
    }
    emit(current.copyWith(selectionMode: true, selectedIds: ids));
  }

  void _onSelectionToggled(
    SelectionToggled event,
    Emitter<TransactionsState> emit,
  ) {
    final current = state;
    if (current is! TransactionsLoaded || !current.selectionMode) return;

    // Guard: yalnız MANUAL işlemler
    final tx = current.transactions
        .where((t) => t.id == event.id)
        .firstOrNull;
    if (tx == null || tx.source != TransactionSource.MANUAL) return;

    final updated = Set<String>.from(current.selectedIds);
    if (updated.contains(event.id)) {
      updated.remove(event.id);
    } else {
      updated.add(event.id);
    }
    emit(current.copyWith(selectedIds: updated));
  }

  void _onSelectionCleared(
    SelectionCleared event,
    Emitter<TransactionsState> emit,
  ) {
    final current = state;
    if (current is! TransactionsLoaded) return;
    emit(current.copyWith(selectionMode: false, selectedIds: {}));
  }

  Future<void> _onBulkDelete(
    BulkDeleteRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    final current = state;
    if (current is! TransactionsLoaded) return;
    if (current.selectedIds.isEmpty) return;

    final ids = List<String>.from(current.selectedIds);

    // Optimistic: seçilenleri listeden çıkar + seçim modunu kapat
    final optimisticTxs = current.transactions
        .where((t) => !current.selectedIds.contains(t.id))
        .toList();
    emit(current.copyWith(
      transactions: optimisticTxs,
      selectionMode: false,
      selectedIds: {},
    ));

    try {
      await _repo.bulkDelete(ids);
      // Özet ve listeyi yenile
      await _fetch(emit);
    } catch (_) {
      // Hata: eski state'e geri dön
      emit(current);
    }
  }

  Future<void> _fetch(Emitter<TransactionsState> emit) async {
    try {
      final results = await Future.wait([
        _repo.getTransactions(
          type: _currentFilter.type,
          categoryId: _currentFilter.categoryId,
          accountId: _currentFilter.accountId,
          startDate: _currentFilter.startDate?.toIso8601String().substring(0, 10),
          endDate: _currentFilter.endDate?.toIso8601String().substring(0, 10),
          search: _currentFilter.search,
          page: 1,
          limit: _pageSize,
        ),
        _repo.getSummary(),
      ]);

      final txResult =
          results[0] as ({List<TransactionModel> data, int total, int totalPages});
      final summary =
          results[1] as ({double income, double expense, double net});

      emit(TransactionsLoaded(
        transactions: txResult.data,
        income: summary.income,
        expense: summary.expense,
        net: summary.net,
        filter: _currentFilter,
        hasMore: txResult.totalPages > 1,
      ));
    } catch (e) {
      emit(TransactionsError(_parseError(e)));
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }
    return 'İşlemler yüklenemedi.';
  }
}
