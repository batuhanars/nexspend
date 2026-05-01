import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/account_analytics_model.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/account_repository.dart';

part 'account_detail_event.dart';
part 'account_detail_state.dart';

class AccountDetailBloc
    extends Bloc<AccountDetailEvent, AccountDetailState> {
  AccountDetailBloc({required AccountRepository accountRepository})
      : _repo = accountRepository,
        super(AccountDetailInitial()) {
    on<AccountDetailLoadRequested>(_onLoad);
    on<AccountDetailRefreshRequested>(_onLoad);
    on<AccountDetailAccountUpdated>(_onAccountUpdated);
  }

  final AccountRepository _repo;

  Future<void> _onLoad(
    AccountDetailEvent event,
    Emitter<AccountDetailState> emit,
  ) async {
    final id = event is AccountDetailLoadRequested
        ? event.accountId
        : (event as AccountDetailRefreshRequested).accountId;

    emit(AccountDetailLoading());
    try {
      final accountFuture = _repo.getAccount(id);
      final analyticsFuture = _repo.getAnalytics(id);
      final txFuture = _repo.getAccountTransactions(id);

      final account = await accountFuture;
      final analytics = await analyticsFuture;
      final transactions = await txFuture;

      emit(AccountDetailLoaded(
        account: account,
        analytics: analytics,
        transactions: transactions,
      ));
    } catch (_) {
      emit(AccountDetailError('Hesap detayları yüklenemedi.'));
    }
  }

  void _onAccountUpdated(
    AccountDetailAccountUpdated event,
    Emitter<AccountDetailState> emit,
  ) {
    final current = state;
    if (current is AccountDetailLoaded) {
      emit(current.copyWith(account: event.account));
    }
  }
}
