part of 'reports_bloc.dart';

sealed class ReportsState {}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  ReportsLoaded({
    required this.distribution,
    required this.cashFlow,
    required this.trends,
    required this.period,
  });

  final List<ExpenseDistributionItem> distribution;
  final List<CashFlowItem> cashFlow;
  final List<TrendItem> trends;
  final String period;
}

class ReportsError extends ReportsState {
  ReportsError(this.message);
  final String message;
}
