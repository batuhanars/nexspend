part of 'receipt_history_bloc.dart';

sealed class ReceiptHistoryEvent {}

class ReceiptHistoryLoadRequested extends ReceiptHistoryEvent {}

class ReceiptHistoryRefreshRequested extends ReceiptHistoryEvent {}

class ReceiptHistoryDeleteRequested extends ReceiptHistoryEvent {
  ReceiptHistoryDeleteRequested(this.id);
  final String id;
}
