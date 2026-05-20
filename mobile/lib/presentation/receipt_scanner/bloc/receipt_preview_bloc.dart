import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/receipt_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/family_model.dart';
import '../../../data/repositories/receipt_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/family_repository.dart';
import '../helper/account_matcher.dart';

part 'receipt_preview_event.dart';
part 'receipt_preview_state.dart';

class ReceiptPreviewBloc
    extends Bloc<ReceiptPreviewEvent, ReceiptPreviewState> {
  ReceiptPreviewBloc({
    required ReceiptRepository receiptRepository,
    required CategoryRepository categoryRepository,
    required AccountRepository accountRepository,
    required FamilyRepository familyRepository,
    required ReceiptParseResult initialResult,
    String? initialCategoryId,
    String? initialSharedBudgetId,
  })  : _receiptRepo = receiptRepository,
        _categoryRepo = categoryRepository,
        _accountRepo = accountRepository,
        _familyRepo = familyRepository,
        _initialCategoryId = initialCategoryId,
        _initialSharedBudgetId = initialSharedBudgetId,
        super(ReceiptPreviewInitial()) {
    on<ReceiptPreviewLoaded>(_onLoaded);
    on<ReceiptPreviewFieldUpdated>(_onFieldUpdated);
    on<ReceiptPreviewConfirmed>(_onConfirmed);
    on<ReceiptPreviewAccountAdded>(_onAccountAdded);
    on<ReceiptPreviewSharedBudgetSelected>(_onSharedBudgetSelected);

    add(ReceiptPreviewLoaded(result: initialResult));
  }

  final ReceiptRepository _receiptRepo;
  final CategoryRepository _categoryRepo;
  final AccountRepository _accountRepo;
  final FamilyRepository _familyRepo;
  final String? _initialCategoryId;
  final String? _initialSharedBudgetId;

  Future<void> _onLoaded(
    ReceiptPreviewLoaded event,
    Emitter<ReceiptPreviewState> emit,
  ) async {
    emit(ReceiptPreviewInitial());
    try {
      final allCategories = await _categoryRepo.getCategories();
      // Fiş = gider; INCOME kategorileri (Maaş, Freelance vb.) listelenmez.
      final categories = allCategories
          .where((c) =>
              c.type == CategoryType.EXPENSE || c.type == CategoryType.BOTH)
          .toList();
      final accounts = await _accountRepo.getAccounts();
      // Ortak bütçeler eksik kalsa da fiş akışı çalışabilmeli — sessizce yut.
      List<MySharedBudgetModel> mySharedBudgets = const [];
      try {
        mySharedBudgets = await _familyRepo.getMySharedBudgets();
      } catch (_) {}

      // Önce backend hint'iyle eşleşme dene — banka adı veya ödeme tipi.
      final hint = event.result.suggestedAccountHint;
      final matched = ReceiptAccountMatcher.match(hint, accounts);
      final fallbackDefault = accounts.isNotEmpty
          ? accounts.firstWhere(
              (a) => a.isDefault,
              orElse: () => accounts.first,
            )
          : null;
      final selectedAccountId = matched?.id ?? fallbackDefault?.id;

      // Hint'te banka/nakit tespit var ama eşleşen hesap yoksa CTA için işaretle.
      final unmatchedBankName =
          matched == null && hint?.bankName != null ? hint!.bankName : null;
      final unmatchedCash = matched == null &&
          hint?.paymentMethod == 'CASH' &&
          !accounts.any((a) => !a.isArchived && a.type == AccountType.CASH);

      // Budget detayından açıldıysa o bütçenin kategorisini ön-seçili getir;
      // yoksa AI önerisine düş. Kategori listede yoksa (örn. INCOME) yine AI'a düş.
      final preselectedCategoryId =
          (_initialCategoryId != null &&
                  categories.any((c) => c.id == _initialCategoryId))
              ? _initialCategoryId
              : event.result.suggestedCategoryId;

      // Ortak bütçe detayından açıldıysa o bütçeyi ön-seçili getir
      // (kullanıcının mySharedBudgets listesinde gerçekten var olduğunu doğrula).
      final preselectedSharedBudgetId = (_initialSharedBudgetId != null &&
              mySharedBudgets.any((b) => b.id == _initialSharedBudgetId))
          ? _initialSharedBudgetId
          : null;

      emit(ReceiptPreviewReady(
        result: event.result,
        categories: categories,
        accounts: accounts,
        mySharedBudgets: mySharedBudgets,
        selectedCategoryId: preselectedCategoryId,
        selectedAccountId: selectedAccountId,
        selectedSharedBudgetId: preselectedSharedBudgetId,
        isBudgetLocked: _initialCategoryId != null,
        unmatchedBankName: unmatchedBankName,
        unmatchedCash: unmatchedCash,
      ));
    } catch (e) {
      emit(ReceiptPreviewError(e.toString()));
    }
  }

  void _onFieldUpdated(
    ReceiptPreviewFieldUpdated event,
    Emitter<ReceiptPreviewState> emit,
  ) {
    if (state is! ReceiptPreviewReady) return;
    final current = state as ReceiptPreviewReady;
    // Kategori değiştiyse ortak bütçe seçimi de geçersiz olur — sıfırla.
    // Aynı zamanda kilitliyse kilidi kır: user'ın niyeti değişmiş demektir.
    final categoryChanged = event.categoryId != null &&
        event.categoryId != current.selectedCategoryId;
    emit(current.copyWith(
      amount: event.amount,
      date: event.date,
      merchantName: event.merchantName,
      selectedCategoryId: event.categoryId,
      selectedAccountId: event.accountId,
      clearSelectedSharedBudgetId: categoryChanged,
      isBudgetLocked: categoryChanged ? false : current.isBudgetLocked,
    ));
  }

  void _onSharedBudgetSelected(
    ReceiptPreviewSharedBudgetSelected event,
    Emitter<ReceiptPreviewState> emit,
  ) {
    if (state is! ReceiptPreviewReady) return;
    final current = state as ReceiptPreviewReady;
    emit(current.copyWith(
      selectedSharedBudgetId: event.sharedBudgetId,
      clearSelectedSharedBudgetId: event.sharedBudgetId == null,
    ));
  }

  void _onAccountAdded(
    ReceiptPreviewAccountAdded event,
    Emitter<ReceiptPreviewState> emit,
  ) {
    if (state is! ReceiptPreviewReady) return;
    final current = state as ReceiptPreviewReady;
    emit(current.copyWith(
      accounts: [...current.accounts, event.account],
      selectedAccountId: event.account.id,
      clearUnmatchedBankName: true,
      unmatchedCash: false,
    ));
  }

  Future<void> _onConfirmed(
    ReceiptPreviewConfirmed event,
    Emitter<ReceiptPreviewState> emit,
  ) async {
    if (state is! ReceiptPreviewReady) return;
    final current = state as ReceiptPreviewReady;
    emit(current.copyWith(isSubmitting: true));

    try {
      final receiptId = current.result.receiptId;
      if (receiptId == null) throw Exception('Makbuz ID bulunamadı');

      await _receiptRepo.confirmAndCreateTransaction(receiptId, {
        'amount': current.effectiveAmount,
        'transactionDate': current.effectiveDate.toIso8601String(),
        'merchant': current.effectiveMerchant,
        if (current.selectedCategoryId != null)
          'categoryId': current.selectedCategoryId,
        'accountId': current.selectedAccountId,
        if (current.selectedSharedBudgetId != null)
          'sharedBudgetId': current.selectedSharedBudgetId,
      });

      emit(ReceiptPreviewSuccess());
    } catch (e) {
      emit(current.copyWith(
        isSubmitting: false,
        errorMessage: _extractErrorMessage(e),
      ));
    }
  }

  String _extractErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        // GlobalExceptionFilter validation'da message="Validation failed"
        // gönderip detayları errors[] alanına atıyor; önce o listeye bak.
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) return errors.join(', ');
        final msg = data['message'];
        if (msg is List && msg.isNotEmpty) return msg.join(', ');
        if (msg is String && msg.isNotEmpty) return msg;
      }
      if (data is String && data.isNotEmpty) return data;
    }
    return e.toString();
  }
}
