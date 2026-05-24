part of 'transactions_bloc.dart';

sealed class TransactionsEvent {}

class TransactionsLoadRequested extends TransactionsEvent {}

class TransactionsRefreshRequested extends TransactionsEvent {}

class TransactionsLoadMoreRequested extends TransactionsEvent {}

class TransactionsFilterChanged extends TransactionsEvent {
  TransactionsFilterChanged(this.filter);
  final TransactionFilter filter;
}

class TransactionDeleteRequested extends TransactionsEvent {
  TransactionDeleteRequested(this.id);
  final String id;
}

// Seçim modu event'leri
class SelectionModeEntered extends TransactionsEvent {
  SelectionModeEntered({this.initialId});
  final String? initialId;
}

class SelectionToggled extends TransactionsEvent {
  SelectionToggled(this.id);
  final String id;
}

class SelectionCleared extends TransactionsEvent {}

class BulkDeleteRequested extends TransactionsEvent {}
