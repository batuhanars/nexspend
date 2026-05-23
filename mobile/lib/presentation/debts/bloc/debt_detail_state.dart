part of 'debt_detail_bloc.dart';

sealed class DebtDetailState {}

class DebtDetailInitial extends DebtDetailState {}

class DebtDetailLoading extends DebtDetailState {}

class DebtDetailLoaded extends DebtDetailState {
  DebtDetailLoaded({
    required this.debt,
    required this.installments,
    required this.payments,
  });

  final DebtModel debt;
  final List<DebtInstallmentModel> installments;
  final List<DebtPaymentModel> payments;
}

class DebtDetailError extends DebtDetailState {
  DebtDetailError(this.message);
  final String message;
}

class DebtDetailDeleted extends DebtDetailState {}
