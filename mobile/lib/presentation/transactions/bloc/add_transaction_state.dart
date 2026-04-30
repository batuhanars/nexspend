part of 'add_transaction_bloc.dart';

sealed class AddTransactionState {}

class AddTransactionInitial extends AddTransactionState {}

class AddTransactionDataLoading extends AddTransactionState {}

class AddTransactionReady extends AddTransactionState {
  AddTransactionReady({required this.categories, required this.accounts});
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
}

class AddTransactionSubmitting extends AddTransactionState {
  AddTransactionSubmitting({required this.categories, required this.accounts});
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
}

class AddTransactionSuccess extends AddTransactionState {
  AddTransactionSuccess(this.transaction);
  final TransactionModel transaction;
}

class AddTransactionFailure extends AddTransactionState {
  AddTransactionFailure({
    required this.message,
    required this.categories,
    required this.accounts,
  });
  final String message;
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
}
