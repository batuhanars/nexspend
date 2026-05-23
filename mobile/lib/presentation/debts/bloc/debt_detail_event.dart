part of 'debt_detail_bloc.dart';

sealed class DebtDetailEvent {}

class DebtDetailLoadRequested extends DebtDetailEvent {
  DebtDetailLoadRequested({required this.debt});
  final DebtModel debt;
}

class DebtDetailRefreshRequested extends DebtDetailEvent {}

class DebtDetailPaymentMade extends DebtDetailEvent {
  DebtDetailPaymentMade(this.data);
  final Map<String, dynamic> data;
}

class DebtDetailDeleteRequested extends DebtDetailEvent {}
