part of 'debts_bloc.dart';

sealed class DebtsEvent {
  const DebtsEvent();
}

class DebtsLoadRequested extends DebtsEvent {
  const DebtsLoadRequested();
}

class DebtsRefreshRequested extends DebtsEvent {
  const DebtsRefreshRequested();
}

class DebtsFilterChanged extends DebtsEvent {
  const DebtsFilterChanged(this.filter);
  final String? filter;
}

class DebtDeleteRequested extends DebtsEvent {
  const DebtDeleteRequested(this.id);
  final String id;
}

class DebtCreated extends DebtsEvent {
  const DebtCreated(this.data);
  final Map<String, dynamic> data;
}

class DebtPaymentRecorded extends DebtsEvent {
  const DebtPaymentRecorded({required this.debtId, required this.data});
  final String debtId;
  final Map<String, dynamic> data;
}
