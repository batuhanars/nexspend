part of 'account_detail_bloc.dart';

sealed class AccountDetailState {}

class AccountDetailInitial extends AccountDetailState {}

class AccountDetailLoading extends AccountDetailState {}

class AccountDetailLoaded extends AccountDetailState {
  AccountDetailLoaded({
    required this.account,
    required this.analytics,
    required this.transactions,
  });

  final AccountModel account;
  final AccountAnalyticsModel analytics;
  final List<TransactionModel> transactions;

  AccountDetailLoaded copyWith({
    AccountModel? account,
    AccountAnalyticsModel? analytics,
    List<TransactionModel>? transactions,
  }) =>
      AccountDetailLoaded(
        account: account ?? this.account,
        analytics: analytics ?? this.analytics,
        transactions: transactions ?? this.transactions,
      );
}

class AccountDetailError extends AccountDetailState {
  AccountDetailError(this.message);
  final String message;
}
