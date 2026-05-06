part of 'statements_bloc.dart';

sealed class StatementsState {
  const StatementsState();
}

class StatementsInitial extends StatementsState {
  const StatementsInitial();
}

class StatementsLoading extends StatementsState {
  const StatementsLoading();
}

class StatementsError extends StatementsState {
  const StatementsError(this.message);
  final String message;
}

class StatementsLoaded extends StatementsState {
  const StatementsLoaded({
    required this.response,
    required this.payableAccounts,
    this.isPaying = false,
    this.payError,
    this.paymentSuccess = false,
  });

  final AccountStatementsResponse response;
  final List<AccountModel> payableAccounts;
  final bool isPaying;
  final String? payError;
  final bool paymentSuccess;

  StatementsLoaded copyWith({
    AccountStatementsResponse? response,
    List<AccountModel>? payableAccounts,
    bool? isPaying,
    String? payError,
    bool? paymentSuccess,
  }) =>
      StatementsLoaded(
        response: response ?? this.response,
        payableAccounts: payableAccounts ?? this.payableAccounts,
        isPaying: isPaying ?? this.isPaying,
        payError: payError,
        paymentSuccess: paymentSuccess ?? false,
      );
}
