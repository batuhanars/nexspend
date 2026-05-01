part of 'add_transaction_bloc.dart';

sealed class AddTransactionState {}

class AddTransactionInitial extends AddTransactionState {}

class AddTransactionDataLoading extends AddTransactionState {}

class AddTransactionReady extends AddTransactionState {
  AddTransactionReady({
    required this.categories,
    required this.accounts,
    required this.tags,
  });
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final List<TagModel> tags;
}

class AddTransactionSubmitting extends AddTransactionState {
  AddTransactionSubmitting({
    required this.categories,
    required this.accounts,
    required this.tags,
  });
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final List<TagModel> tags;
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
    required this.tags,
  });
  final String message;
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final List<TagModel> tags;
}
