part of 'receipt_preview_bloc.dart';

sealed class ReceiptPreviewState {
  const ReceiptPreviewState();
}

class ReceiptPreviewInitial extends ReceiptPreviewState {}

class ReceiptPreviewError extends ReceiptPreviewState {
  const ReceiptPreviewError(this.message);
  final String message;
}

class ReceiptPreviewSuccess extends ReceiptPreviewState {}

class ReceiptPreviewReady extends ReceiptPreviewState {
  const ReceiptPreviewReady({
    required this.result,
    required this.categories,
    required this.accounts,
    this.selectedCategoryId,
    this.selectedAccountId,
    this.overrideAmount,
    this.overrideDate,
    this.overrideMerchant,
    this.isSubmitting = false,
    this.errorMessage,
    this.unmatchedBankName,
    this.unmatchedCash = false,
  });

  final ReceiptParseResult result;
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final String? selectedCategoryId;
  final String? selectedAccountId;
  final double? overrideAmount;
  final DateTime? overrideDate;
  final String? overrideMerchant;
  final bool isSubmitting;
  final String? errorMessage;

  /// Backend banka adı tespit etti ama kullanıcının hesap listesinde eşleşen
  /// hesap yok → UI "Hesap ekle" CTA'sı gösterir.
  final String? unmatchedBankName;

  /// Backend nakit ödeme tespit etti ama kullanıcının CASH tipinde hesabı yok.
  final bool unmatchedCash;

  double get effectiveAmount => overrideAmount ?? result.amount ?? 0.0;
  DateTime get effectiveDate => overrideDate ?? result.date ?? DateTime.now();
  String get effectiveMerchant =>
      overrideMerchant ?? result.merchantName ?? '';

  ReceiptPreviewReady copyWith({
    ReceiptParseResult? result,
    List<CategoryModel>? categories,
    List<AccountModel>? accounts,
    String? selectedCategoryId,
    String? selectedAccountId,
    double? amount,
    DateTime? date,
    String? merchantName,
    bool? isSubmitting,
    String? errorMessage,
    String? unmatchedBankName,
    bool clearUnmatchedBankName = false,
    bool? unmatchedCash,
  }) =>
      ReceiptPreviewReady(
        result: result ?? this.result,
        categories: categories ?? this.categories,
        accounts: accounts ?? this.accounts,
        selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
        selectedAccountId: selectedAccountId ?? this.selectedAccountId,
        overrideAmount: amount ?? overrideAmount,
        overrideDate: date ?? overrideDate,
        overrideMerchant: merchantName ?? overrideMerchant,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: errorMessage,
        unmatchedBankName: clearUnmatchedBankName
            ? null
            : (unmatchedBankName ?? this.unmatchedBankName),
        unmatchedCash: unmatchedCash ?? this.unmatchedCash,
      );
}
