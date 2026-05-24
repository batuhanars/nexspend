part of 'add_transaction_bloc.dart';

sealed class AddTransactionEvent {}

/// [editingId] doluysa edit modu; init'te prefill verisi hazırlanır.
class AddTransactionInitialized extends AddTransactionEvent {
  AddTransactionInitialized({this.editingId});
  final String? editingId;
}

class AddTransactionSubmitted extends AddTransactionEvent {
  AddTransactionSubmitted(this.data);
  final Map<String, dynamic> data;
}

class AddTransactionTagCreated extends AddTransactionEvent {
  AddTransactionTagCreated(this.name);
  final String name;
}
