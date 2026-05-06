part of 'statements_bloc.dart';

sealed class StatementsEvent {
  const StatementsEvent();
}

class StatementsLoadRequested extends StatementsEvent {
  const StatementsLoadRequested();
}

class StatementPaymentRequested extends StatementsEvent {
  const StatementPaymentRequested({
    required this.statementId,
    required this.amount,
    required this.fromAccountId,
  });

  final String statementId;
  final double amount;
  final String fromAccountId;
}
