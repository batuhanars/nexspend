part of 'add_transaction_bloc.dart';

sealed class AddTransactionState {}

class AddTransactionInitial extends AddTransactionState {}

class AddTransactionDataLoading extends AddTransactionState {}

class AddTransactionReady extends AddTransactionState {
  AddTransactionReady({
    required this.categories,
    required this.accounts,
    required this.tags,
    this.isEditMode = false,
  });
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final List<TagModel> tags;
  final bool isEditMode;
}

class AddTransactionSubmitting extends AddTransactionState {
  AddTransactionSubmitting({
    required this.categories,
    required this.accounts,
    required this.tags,
    this.isEditMode = false,
  });
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final List<TagModel> tags;
  final bool isEditMode;
}

class AddTransactionSuccess extends AddTransactionState {
  AddTransactionSuccess(this.transaction, {this.isEditMode = false});
  final TransactionModel transaction;
  final bool isEditMode;
}

class AddTransactionFailure extends AddTransactionState {
  AddTransactionFailure({
    required this.message,
    required this.categories,
    required this.accounts,
    required this.tags,
    this.isEditMode = false,
  });
  final String message;
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final List<TagModel> tags;
  final bool isEditMode;
}
