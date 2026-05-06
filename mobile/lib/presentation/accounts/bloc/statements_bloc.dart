import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/statement_model.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/statement_repository.dart';

part 'statements_event.dart';
part 'statements_state.dart';

class StatementsBloc extends Bloc<StatementsEvent, StatementsState> {
  StatementsBloc({
    required StatementRepository statementRepository,
    required AccountRepository accountRepository,
    required this.accountId,
  })  : _statementRepo = statementRepository,
        _accountRepo = accountRepository,
        super(const StatementsInitial()) {
    on<StatementsLoadRequested>(_onLoad);
    on<StatementPaymentRequested>(_onPay);
  }

  final StatementRepository _statementRepo;
  final AccountRepository _accountRepo;
  final String accountId;

  Future<void> _onLoad(
    StatementsLoadRequested event,
    Emitter<StatementsState> emit,
  ) async {
    emit(const StatementsLoading());
    try {
      final response = await _statementRepo.getForAccount(accountId);
      final allAccounts = await _accountRepo.getAccounts();
      // Ödeme kaynağı olabilecek hesaplar — kredi kartı ve arşivli olanlar hariç.
      final payable = allAccounts
          .where((a) => !a.isArchived && a.type != AccountType.CREDIT_CARD)
          .toList();
      emit(StatementsLoaded(response: response, payableAccounts: payable));
    } catch (e) {
      emit(StatementsError(e.toString()));
    }
  }

  Future<void> _onPay(
    StatementPaymentRequested event,
    Emitter<StatementsState> emit,
  ) async {
    final current = state;
    if (current is! StatementsLoaded) return;
    emit(current.copyWith(isPaying: true, payError: null));
    try {
      await _statementRepo.pay(
        event.statementId,
        amount: event.amount,
        fromAccountId: event.fromAccountId,
      );
      // Tüm listeyi tazele — ödeme yapılan ekstrenin status'u ve current period
      // (yeni transfer transaction'ı) ikisi de değişti.
      final response = await _statementRepo.getForAccount(accountId);
      emit(StatementsLoaded(
        response: response,
        payableAccounts: current.payableAccounts,
        isPaying: false,
        paymentSuccess: true,
      ));
    } catch (e) {
      emit(current.copyWith(isPaying: false, payError: e.toString()));
    }
  }
}
