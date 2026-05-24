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
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<TransactionModel> transactions;
  final double income;
  final double expense;
  final double net;
  final TransactionFilter filter;
  final bool hasMore;
  final bool isLoadingMore;

  TransactionsLoaded copyWith({
    List<TransactionModel>? transactions,
    double? income,
    double? expense,
    double? net,
    TransactionFilter? filter,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return TransactionsLoaded(
      transactions: transactions ?? this.transactions,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      net: net ?? this.net,
      filter: filter ?? this.filter,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TransactionsError extends TransactionsState {
  TransactionsError(this.message);
  final String message;
}
