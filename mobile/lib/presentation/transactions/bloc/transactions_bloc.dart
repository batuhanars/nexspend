import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

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
  }

  final TransactionRepository _repo;
  String? _currentFilter;
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
        type: _currentFilter,
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

  Future<void> _fetch(Emitter<TransactionsState> emit) async {
    try {
      final results = await Future.wait([
        _repo.getTransactions(
          type: _currentFilter,
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
