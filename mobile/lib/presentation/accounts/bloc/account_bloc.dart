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
    on<AccountUpdateRequested>(_onUpdate);
    on<AccountArchiveRequested>(_onArchive);
    on<AccountSetDefaultRequested>(_onSetDefault);
    on<AccountDeleteRequested>(_onDelete);
    on<AccountRestoreRequested>(_onRestore);
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

  Future<void> _onUpdate(
    AccountUpdateRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountSubmitting());
    try {
      final account = await _repo.updateAccount(event.id, event.data);
      emit(AccountSuccess(account));
    } catch (e) {
      emit(AccountError(_parseError(e)));
    }
  }

  Future<void> _onArchive(
    AccountArchiveRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountSubmitting());
    try {
      await _repo.archiveAccount(event.id);
      emit(AccountActionDone('Hesap arşivlendi'));
    } catch (e) {
      emit(AccountError(_parseError(e)));
    }
  }

  Future<void> _onSetDefault(
    AccountSetDefaultRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountSubmitting());
    try {
      await _repo.setDefaultAccount(event.id);
      emit(AccountActionDone('Varsayılan hesap güncellendi'));
    } catch (e) {
      emit(AccountError(_parseError(e)));
    }
  }

  Future<void> _onDelete(
    AccountDeleteRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountSubmitting());
    try {
      await _repo.deleteAccount(event.id);
      emit(AccountDeleted());
    } catch (e) {
      emit(AccountError(_parseError(e, isDelete: true)));
    }
  }

  Future<void> _onRestore(
    AccountRestoreRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountSubmitting());
    try {
      await _repo.restoreAccount(event.id);
      emit(AccountActionDone('Hesap geri yüklendi'));
    } catch (e) {
      emit(AccountError(_parseError(e)));
    }
  }

  String _parseError(Object e, {bool isDelete = false}) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }
    if (msg.contains('401')) return 'Oturum süreniz doldu.';
    if (isDelete && msg.contains('400')) {
      return 'İşlem geçmişi olan hesap silinemez. Arşivlemeyi deneyin.';
    }
    return 'İşlem gerçekleştirilemedi. Lütfen tekrar deneyin.';
  }
}
