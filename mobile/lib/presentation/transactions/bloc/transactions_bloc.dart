import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/date_formatter.dart';
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
    on<TransactionsFilterChanged>(_onFilterChanged);
    on<TransactionDeleteRequested>(_onDelete);
  }

  final TransactionRepository _repo;
  String? _currentFilter;

  Future<void> _onLoad(
    TransactionsLoadRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(TransactionsLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    TransactionsRefreshRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    await _fetch(emit);
  }

  Future<void> _onFilterChanged(
    TransactionsFilterChanged event,
    Emitter<TransactionsState> emit,
  ) async {
    _currentFilter = event.filter;
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
        _repo.getTransactions(type: _currentFilter, limit: 50),
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
