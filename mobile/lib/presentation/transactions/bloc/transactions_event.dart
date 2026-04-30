part of 'transactions_bloc.dart';

sealed class TransactionsEvent {}

class TransactionsLoadRequested extends TransactionsEvent {}

class TransactionsRefreshRequested extends TransactionsEvent {}

class TransactionsFilterChanged extends TransactionsEvent {
  TransactionsFilterChanged(this.filter);
  final String? filter; // null = hepsi
}

class TransactionDeleteRequested extends TransactionsEvent {
  TransactionDeleteRequested(this.id);
  final String id;
}
