import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/receipt_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/account_model.dart';
import '../../../data/repositories/receipt_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/account_repository.dart';
import '../helper/account_matcher.dart';

part 'receipt_preview_event.dart';
part 'receipt_preview_state.dart';

class ReceiptPreviewBloc
    extends Bloc<ReceiptPreviewEvent, ReceiptPreviewState> {
  ReceiptPreviewBloc({
    required ReceiptRepository receiptRepository,
    required CategoryRepository categoryRepository,
    required AccountRepository accountRepository,
    required ReceiptParseResult initialResult,
  })  : _receiptRepo = receiptRepository,
        _categoryRepo = categoryRepository,
        _accountRepo = accountRepository,
        super(ReceiptPreviewInitial()) {
    on<ReceiptPreviewLoaded>(_onLoaded);
    on<ReceiptPreviewFieldUpdated>(_onFieldUpdated);
    on<ReceiptPreviewConfirmed>(_onConfirmed);
    on<ReceiptPreviewAccountAdded>(_onAccountAdded);

    add(ReceiptPreviewLoaded(result: initialResult));
  }

  final ReceiptRepository _receiptRepo;
  final CategoryRepository _categoryRepo;
  final AccountRepository _accountRepo;

  Future<void> _onLoaded(
    ReceiptPreviewLoaded event,
    Emitter<ReceiptPreviewState> emit,
  ) async {
    emit(ReceiptPreviewInitial());
    try {
      final categories = await _categoryRepo.getCategories();
      final accounts = await _accountRepo.getAccounts();

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

      emit(ReceiptPreviewReady(
        result: event.result,
        categories: categories,
        accounts: accounts,
        selectedCategoryId: event.result.suggestedCategoryId,
        selectedAccountId: selectedAccountId,
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
    emit(current.copyWith(
      amount: event.amount,
      date: event.date,
      merchantName: event.merchantName,
      selectedCategoryId: event.categoryId,
      selectedAccountId: event.accountId,
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
      });

      emit(ReceiptPreviewSuccess());
    } catch (e) {
      emit(current.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }
}
