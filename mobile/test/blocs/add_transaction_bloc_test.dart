import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/data/models/account_model.dart';
import 'package:wallet_app/data/models/category_model.dart';
import 'package:wallet_app/data/models/tag_model.dart';
import 'package:wallet_app/data/models/transaction_model.dart';
import 'package:wallet_app/data/repositories/account_repository.dart';
import 'package:wallet_app/data/repositories/category_repository.dart';
import 'package:wallet_app/data/repositories/tag_repository.dart';
import 'package:wallet_app/data/repositories/transaction_repository.dart';
import 'package:wallet_app/presentation/transactions/bloc/add_transaction_bloc.dart';

class MockTransactionRepository extends Mock
    implements TransactionRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockTagRepository extends Mock implements TagRepository {}

// Sabit test verisi
final _cat1 = CategoryModel(
  id: 'cat-1',
  name: 'Market',
  icon: 'shopping_cart',
  color: '#BAC3FF',
  type: CategoryType.EXPENSE,
);

final _acc1 = AccountModel(
  id: 'acc-1',
  name: 'Ziraat',
  type: AccountType.BANK,
  balance: 5000.0,
  currency: 'TRY',
  isDefault: true,
  isArchived: false,
);

final _tag1 = TagModel(id: 'tag-1', name: 'Önemli');

final _tx = TransactionModel(
  id: 'tx-1',
  amount: 150.0,
  type: TransactionType.EXPENSE,
  source: TransactionSource.MANUAL,
  date: DateTime(2026, 5, 1),
);

void main() {
  late MockTransactionRepository txRepo;
  late MockCategoryRepository catRepo;
  late MockAccountRepository accRepo;
  late MockTagRepository tagRepo;

  setUp(() {
    txRepo = MockTransactionRepository();
    catRepo = MockCategoryRepository();
    accRepo = MockAccountRepository();
    tagRepo = MockTagRepository();

    when(() => catRepo.getCategories())
        .thenAnswer((_) async => [_cat1]);
    when(() => accRepo.getAccounts())
        .thenAnswer((_) async => [_acc1]);
    when(() => tagRepo.getAll())
        .thenAnswer((_) async => [_tag1]);
  });

  AddTransactionBloc buildBloc({String? editingId}) => AddTransactionBloc(
        transactionRepository: txRepo,
        categoryRepository: catRepo,
        accountRepository: accRepo,
        tagRepository: tagRepo,
      );

  group('AddTransactionInitialized — create modu', () {
    blocTest<AddTransactionBloc, AddTransactionState>(
      'başarılı init → DataLoading → Ready (isEditMode=false)',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(AddTransactionInitialized()),
      expect: () => [
        isA<AddTransactionDataLoading>(),
        isA<AddTransactionReady>()
            .having((s) => s.isEditMode, 'isEditMode', false)
            .having((s) => s.categories.length, 'categories', 1)
            .having((s) => s.accounts.length, 'accounts', 1),
      ],
    );
  });

  group('AddTransactionInitialized — edit modu', () {
    blocTest<AddTransactionBloc, AddTransactionState>(
      'editingId dolu → Ready (isEditMode=true)',
      build: () => buildBloc(),
      act: (bloc) =>
          bloc.add(AddTransactionInitialized(editingId: 'tx-1')),
      expect: () => [
        isA<AddTransactionDataLoading>(),
        isA<AddTransactionReady>()
            .having((s) => s.isEditMode, 'isEditMode', true),
      ],
    );
  });

  group('AddTransactionSubmitted — create modu', () {
    blocTest<AddTransactionBloc, AddTransactionState>(
      'başarılı create → Submitting → Success (isEditMode=false)',
      build: () {
        when(() => txRepo.createTransaction(any()))
            .thenAnswer((_) async => _tx);
        return buildBloc();
      },
      seed: () => AddTransactionReady(
        categories: [_cat1],
        accounts: [_acc1],
        tags: [_tag1],
        isEditMode: false,
      ),
      act: (bloc) => bloc.add(AddTransactionSubmitted({
        'type': 'EXPENSE',
        'amount': 150.0,
        'accountId': 'acc-1',
        'categoryId': 'cat-1',
        'transactionDate': '2026-05-01T00:00:00.000Z',
        'isRecurring': false,
      })),
      expect: () => [
        isA<AddTransactionSubmitting>()
            .having((s) => s.isEditMode, 'isEditMode', false),
        isA<AddTransactionSuccess>()
            .having((s) => s.isEditMode, 'isEditMode', false)
            .having((s) => s.transaction.id, 'id', 'tx-1'),
      ],
      verify: (_) {
        verify(() => txRepo.createTransaction(any())).called(1);
        verifyNever(() => txRepo.updateTransaction(any(), any()));
      },
    );

    blocTest<AddTransactionBloc, AddTransactionState>(
      'create başarısız → Failure',
      build: () {
        when(() => txRepo.createTransaction(any()))
            .thenThrow(Exception('400 Bad Request'));
        return buildBloc();
      },
      seed: () => AddTransactionReady(
        categories: [_cat1],
        accounts: [_acc1],
        tags: [_tag1],
      ),
      act: (bloc) => bloc.add(AddTransactionSubmitted({
        'type': 'EXPENSE',
        'amount': 150.0,
        'accountId': 'acc-1',
        'isRecurring': false,
      })),
      expect: () => [
        isA<AddTransactionSubmitting>(),
        isA<AddTransactionFailure>()
            .having((s) => s.message, 'message', contains('Geçersiz')),
      ],
    );
  });

  group('AddTransactionSubmitted — edit modu (PATCH)', () {
    blocTest<AddTransactionBloc, AddTransactionState>(
      'başarılı PATCH → Submitting → Success (isEditMode=true)',
      build: () {
        when(() => txRepo.updateTransaction('tx-1', any()))
            .thenAnswer((_) async => _tx);
        return buildBloc();
      },
      seed: () => AddTransactionReady(
        categories: [_cat1],
        accounts: [_acc1],
        tags: [_tag1],
        isEditMode: true,
      ),
      act: (bloc) {
        // Önce editingId set etmek için init ekleyelim;
        // ancak seed ile Ready'ye geçtik — _editingId private.
        // Doğrudan _editingId test edemiyoruz ama bloc'u
        // AddTransactionInitialized(editingId:'tx-1') ile başlatıp
        // sonra submit edelim.
        bloc.add(AddTransactionInitialized(editingId: 'tx-1'));
        bloc.add(AddTransactionSubmitted({
          'type': 'EXPENSE',
          'amount': 200.0,
          'accountId': 'acc-1',
          'transactionDate': '2026-05-01T00:00:00.000Z',
          // isRecurring yok — edit modunda zaten gönderilmez
        }));
      },
      expect: () => [
        isA<AddTransactionDataLoading>(),
        isA<AddTransactionReady>().having((s) => s.isEditMode, 'edit', true),
        isA<AddTransactionSubmitting>()
            .having((s) => s.isEditMode, 'edit', true),
        isA<AddTransactionSuccess>()
            .having((s) => s.isEditMode, 'isEditMode', true),
      ],
      verify: (_) {
        verify(() => txRepo.updateTransaction('tx-1', any())).called(1);
        verifyNever(() => txRepo.createTransaction(any()));
      },
    );

    blocTest<AddTransactionBloc, AddTransactionState>(
      'PATCH başarısız → Failure (isEditMode=true)',
      build: () {
        when(() => txRepo.updateTransaction(any(), any()))
            .thenThrow(Exception('500'));
        return buildBloc();
      },
      act: (bloc) {
        bloc.add(AddTransactionInitialized(editingId: 'tx-1'));
        bloc.add(AddTransactionSubmitted({
          'type': 'EXPENSE',
          'amount': 200.0,
          'accountId': 'acc-1',
          'transactionDate': '2026-05-01T00:00:00.000Z',
        }));
      },
      expect: () => [
        isA<AddTransactionDataLoading>(),
        isA<AddTransactionReady>(),
        isA<AddTransactionSubmitting>(),
        isA<AddTransactionFailure>()
            .having((s) => s.isEditMode, 'isEditMode', true)
            .having(
              (s) => s.message,
              'message',
              contains('güncellenemedi'),
            ),
      ],
    );
  });
}
