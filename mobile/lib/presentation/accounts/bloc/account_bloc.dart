import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/account_model.dart';
import '../../../data/repositories/account_repository.dart';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc({required AccountRepository accountRepository})
      : _repo = accountRepository,
        super(AccountInitial()) {
    on<AccountCreateRequested>(_onCreate);
  }

  final AccountRepository _repo;

  Future<void> _onCreate(
    AccountCreateRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountSubmitting());
    try {
      final account = await _repo.createAccount(event.data);
      emit(AccountSuccess(account));
    } catch (e) {
      emit(AccountError(_parseError(e)));
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }
    if (msg.contains('401')) return 'Oturum süreniz doldu.';
    return 'Hesap oluşturulamadı. Lütfen tekrar deneyin.';
  }
}
