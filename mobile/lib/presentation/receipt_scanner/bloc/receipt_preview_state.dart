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
    this.mySharedBudgets = const [],
    this.selectedCategoryId,
    this.selectedAccountId,
    this.selectedSharedBudgetId,
    this.overrideAmount,
    this.overrideDate,
    this.overrideMerchant,
    this.isSubmitting = false,
    this.errorMessage,
    this.unmatchedBankName,
    this.unmatchedCash = false,
    this.isBudgetLocked = false,
  });

  final ReceiptParseResult result;
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final List<MySharedBudgetModel> mySharedBudgets;
  final String? selectedCategoryId;
  final String? selectedAccountId;
  /// null = "Kişisel"; doluysa seçilen ortak bütçenin id'si.
  final String? selectedSharedBudgetId;
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

  /// Fiş bir bütçe detayından açıldıysa true: bütçe kapsamı chip'leri kilitli
  /// (tek seçenek gösterilir / tamamen gizlenir). Kullanıcı kategoriyi
  /// değiştirirse kilit kırılır (niyet değişmiş demektir).
  final bool isBudgetLocked;

  double get effectiveAmount => overrideAmount ?? result.amount ?? 0.0;
  DateTime get effectiveDate => overrideDate ?? result.date ?? DateTime.now();
  String get effectiveMerchant =>
      overrideMerchant ?? result.merchantName ?? '';

  /// Seçili kategoriye bağlı (kendisi veya parent'ı eşleşen) ortak bütçeler.
  List<MySharedBudgetModel> get sharedBudgetsForSelectedCategory {
    final cid = selectedCategoryId;
    if (cid == null) return const [];
    final matches = categories.where((c) => c.id == cid).toList();
    if (matches.isEmpty) return const [];
    final cat = matches.first;
    return mySharedBudgets
        .where((b) => b.categoryId == cat.id || b.categoryId == cat.parentId)
        .toList();
  }

  ReceiptPreviewReady copyWith({
    ReceiptParseResult? result,
    List<CategoryModel>? categories,
    List<AccountModel>? accounts,
    List<MySharedBudgetModel>? mySharedBudgets,
    String? selectedCategoryId,
    String? selectedAccountId,
    String? selectedSharedBudgetId,
    bool clearSelectedSharedBudgetId = false,
    double? amount,
    DateTime? date,
    String? merchantName,
    bool? isSubmitting,
    String? errorMessage,
    String? unmatchedBankName,
    bool clearUnmatchedBankName = false,
    bool? unmatchedCash,
    bool? isBudgetLocked,
  }) =>
      ReceiptPreviewReady(
        result: result ?? this.result,
        categories: categories ?? this.categories,
        accounts: accounts ?? this.accounts,
        mySharedBudgets: mySharedBudgets ?? this.mySharedBudgets,
        selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
        selectedAccountId: selectedAccountId ?? this.selectedAccountId,
        selectedSharedBudgetId: clearSelectedSharedBudgetId
            ? null
            : (selectedSharedBudgetId ?? this.selectedSharedBudgetId),
        overrideAmount: amount ?? overrideAmount,
        overrideDate: date ?? overrideDate,
        overrideMerchant: merchantName ?? overrideMerchant,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: errorMessage,
        unmatchedBankName: clearUnmatchedBankName
            ? null
            : (unmatchedBankName ?? this.unmatchedBankName),
        unmatchedCash: unmatchedCash ?? this.unmatchedCash,
        isBudgetLocked: isBudgetLocked ?? this.isBudgetLocked,
      );
}
