part of 'debts_bloc.dart';

sealed class DebtsState {}

class DebtsInitial extends DebtsState {}

class DebtsLoading extends DebtsState {}

class DebtsLoaded extends DebtsState {
  DebtsLoaded({
    required this.debts,
    required this.summary,
    this.filter,
  });

  final List<DebtModel> debts;
  final DebtSummaryModel summary;
  final String? filter;

  List<DebtModel> get lentDebts =>
      debts.where((d) => d.type == DebtType.LENT).toList();
  List<DebtModel> get borrowedDebts =>
      debts.where((d) => d.type == DebtType.BORROWED).toList();
  List<DebtModel> get overdueDebts =>
      debts.where((d) => d.status == DebtStatus.OVERDUE).toList();

  DebtsLoaded copyWith({
    List<DebtModel>? debts,
    DebtSummaryModel? summary,
    String? filter,
  }) =>
      DebtsLoaded(
        debts: debts ?? this.debts,
        summary: summary ?? this.summary,
        filter: filter ?? this.filter,
      );
}

class DebtsError extends DebtsState {
  DebtsError(this.message);
  final String message;
}
