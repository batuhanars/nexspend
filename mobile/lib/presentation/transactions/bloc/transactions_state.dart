part of 'transactions_bloc.dart';

sealed class TransactionsState {}

class TransactionsInitial extends TransactionsState {}

class TransactionsLoading extends TransactionsState {}

class TransactionsLoaded extends TransactionsState {
  TransactionsLoaded({
    required this.transactions,
    required this.income,
    required this.expense,
    required this.net,
    required this.filter,
  });

  final List<TransactionModel> transactions;
  final double income;
  final double expense;
  final double net;
  final String? filter;

  Map<String, List<TransactionModel>> get grouped {
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    final map = <String, List<TransactionModel>>{};
    for (final t in sorted) {
      final key = DateFormatter.formatGroupHeader(t.date);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }
}

class TransactionsError extends TransactionsState {
  TransactionsError(this.message);
  final String message;
}
