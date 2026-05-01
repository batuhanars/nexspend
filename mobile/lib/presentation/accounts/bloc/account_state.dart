part of 'account_bloc.dart';

sealed class AccountState {}

class AccountInitial extends AccountState {}

class AccountSubmitting extends AccountState {}

class AccountSuccess extends AccountState {
  AccountSuccess(this.account);
  final AccountModel account;
}

class AccountDeleted extends AccountState {}

class AccountActionDone extends AccountState {
  AccountActionDone(this.message);
  final String message;
}

class AccountError extends AccountState {
  AccountError(this.message);
  final String message;
}
