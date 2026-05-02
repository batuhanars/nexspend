part of 'receipt_preview_bloc.dart';

sealed class ReceiptPreviewEvent {
  const ReceiptPreviewEvent();
}

class ReceiptPreviewLoaded extends ReceiptPreviewEvent {
  const ReceiptPreviewLoaded({required this.result});
  final ReceiptParseResult result;
}

class ReceiptPreviewFieldUpdated extends ReceiptPreviewEvent {
  const ReceiptPreviewFieldUpdated({
    this.amount,
    this.date,
    this.merchantName,
    this.categoryId,
    this.accountId,
  });
  final double? amount;
  final DateTime? date;
  final String? merchantName;
  final String? categoryId;
  final String? accountId;
}

class ReceiptPreviewConfirmed extends ReceiptPreviewEvent {
  const ReceiptPreviewConfirmed();
}
