import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/transaction_repository.dart';

part 'add_transaction_event.dart';
part 'add_transaction_state.dart';

class AddTransactionBloc
    extends Bloc<AddTransactionEvent, AddTransactionState> {
  AddTransactionBloc({
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
    required AccountRepository accountRepository,
  })  : _txRepo = transactionRepository,
        _catRepo = categoryRepository,
        _accRepo = accountRepository,
        super(AddTransactionInitial()) {
    on<AddTransactionInitialized>(_onInit);
    on<AddTransactionSubmitted>(_onSubmit);
  }

  final TransactionRepository _txRepo;
  final CategoryRepository _catRepo;
  final AccountRepository _accRepo;

  Future<void> _onInit(
    AddTransactionInitialized event,
    Emitter<AddTransactionState> emit,
  ) async {
    emit(AddTransactionDataLoading());
    try {
      final results = await Future.wait([
        _catRepo.getCategories(),
        _accRepo.getAccounts(),
      ]);
      emit(AddTransactionReady(
        categories: results[0] as List<CategoryModel>,
        accounts: results[1] as List<AccountModel>,
      ));
    } catch (e) {
      emit(AddTransactionFailure(
        message: 'Veriler yüklenemedi.',
        categories: const [],
        accounts: const [],
      ));
    }
  }

  Future<void> _onSubmit(
    AddTransactionSubmitted event,
    Emitter<AddTransactionState> emit,
  ) async {
    final current = state;
    final cats =
        current is AddTransactionReady ? current.categories : <CategoryModel>[];
    final accs =
        current is AddTransactionReady ? current.accounts : <AccountModel>[];

    emit(AddTransactionSubmitting(categories: cats, accounts: accs));
    try {
      final tx = await _txRepo.createTransaction(event.data);
      emit(AddTransactionSuccess(tx));
    } catch (e) {
      emit(AddTransactionFailure(
        message: _parseError(e),
        categories: cats,
        accounts: accs,
      ));
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException')) return 'İnternet bağlantınızı kontrol edin.';
    if (msg.contains('400')) return 'Geçersiz işlem bilgileri.';
    return 'İşlem oluşturulamadı. Tekrar deneyin.';
  }
}
