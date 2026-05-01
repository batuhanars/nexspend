import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/tag_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/transaction_repository.dart';

part 'add_transaction_event.dart';
part 'add_transaction_state.dart';

class AddTransactionBloc
    extends Bloc<AddTransactionEvent, AddTransactionState> {
  AddTransactionBloc({
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
    required AccountRepository accountRepository,
    required TagRepository tagRepository,
  })  : _txRepo = transactionRepository,
        _catRepo = categoryRepository,
        _accRepo = accountRepository,
        _tagRepo = tagRepository,
        super(AddTransactionInitial()) {
    on<AddTransactionInitialized>(_onInit);
    on<AddTransactionSubmitted>(_onSubmit);
    on<AddTransactionTagCreated>(_onTagCreated);
  }

  final TransactionRepository _txRepo;
  final CategoryRepository _catRepo;
  final AccountRepository _accRepo;
  final TagRepository _tagRepo;

  Future<void> _onInit(
    AddTransactionInitialized event,
    Emitter<AddTransactionState> emit,
  ) async {
    emit(AddTransactionDataLoading());
    try {
      final results = await Future.wait([
        _catRepo.getCategories(),
        _accRepo.getAccounts(),
        _tagRepo.getAll(),
      ]);
      emit(AddTransactionReady(
        categories: results[0] as List<CategoryModel>,
        accounts: results[1] as List<AccountModel>,
        tags: results[2] as List<TagModel>,
      ));
    } catch (e) {
      emit(AddTransactionFailure(
        message: 'Veriler yüklenemedi.',
        categories: const [],
        accounts: const [],
        tags: const [],
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
    final tgs =
        current is AddTransactionReady ? current.tags : <TagModel>[];

    emit(AddTransactionSubmitting(categories: cats, accounts: accs, tags: tgs));
    try {
      final data = Map<String, dynamic>.from(event.data);
      final isRecurring = data.remove('isRecurring') as bool? ?? false;

      if (isRecurring) {
        await _txRepo.createRecurringTransaction(data);
        emit(AddTransactionSuccess(TransactionModel(
          id: '',
          amount: (data['amount'] as num).toDouble(),
          type: TransactionType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => TransactionType.EXPENSE,
          ),
          source: TransactionSource.RECURRING,
          date: DateTime.now(),
        )));
      } else {
        final tx = await _txRepo.createTransaction(data);
        emit(AddTransactionSuccess(tx));
      }
    } catch (e) {
      emit(AddTransactionFailure(
        message: _parseError(e),
        categories: cats,
        accounts: accs,
        tags: tgs,
      ));
    }
  }

  Future<void> _onTagCreated(
    AddTransactionTagCreated event,
    Emitter<AddTransactionState> emit,
  ) async {
    final current = state;
    if (current is! AddTransactionReady) return;
    try {
      final tag = await _tagRepo.create(event.name);
      emit(AddTransactionReady(
        categories: current.categories,
        accounts: current.accounts,
        tags: [...current.tags, tag],
      ));
    } catch (_) {}
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException')) return 'İnternet bağlantınızı kontrol edin.';
    if (msg.contains('400')) return 'Geçersiz işlem bilgileri.';
    return 'İşlem oluşturulamadı. Tekrar deneyin.';
  }
}
