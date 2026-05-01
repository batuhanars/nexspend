part of 'add_transaction_bloc.dart';

sealed class AddTransactionEvent {}

class AddTransactionInitialized extends AddTransactionEvent {}

class AddTransactionSubmitted extends AddTransactionEvent {
  AddTransactionSubmitted(this.data);
  final Map<String, dynamic> data;
}

class AddTransactionTagCreated extends AddTransactionEvent {
  AddTransactionTagCreated(this.name);
  final String name;
}
