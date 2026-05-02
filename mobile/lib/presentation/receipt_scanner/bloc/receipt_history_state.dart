part of 'receipt_history_bloc.dart';

sealed class ReceiptHistoryState {}

class ReceiptHistoryInitial extends ReceiptHistoryState {}

class ReceiptHistoryLoading extends ReceiptHistoryState {}

class ReceiptHistoryLoaded extends ReceiptHistoryState {
  ReceiptHistoryLoaded(this.receipts);
  final List<ReceiptHistoryModel> receipts;
}

class ReceiptHistoryError extends ReceiptHistoryState {
  ReceiptHistoryError(this.message);
  final String message;
}
