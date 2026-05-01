part of 'account_detail_bloc.dart';

sealed class AccountDetailEvent {}

class AccountDetailLoadRequested extends AccountDetailEvent {
  AccountDetailLoadRequested({required this.accountId});
  final String accountId;
}

class AccountDetailRefreshRequested extends AccountDetailEvent {
  AccountDetailRefreshRequested({required this.accountId});
  final String accountId;
}

class AccountDetailAccountUpdated extends AccountDetailEvent {
  AccountDetailAccountUpdated(this.account);
  final AccountModel account;
}
