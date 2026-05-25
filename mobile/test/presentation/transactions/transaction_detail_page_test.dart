import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:get_it/get_it.dart';
import 'package:wallet_app/data/models/transaction_model.dart';
import 'package:wallet_app/data/repositories/account_repository.dart';
import 'package:wallet_app/data/repositories/category_repository.dart';
import 'package:wallet_app/data/repositories/tag_repository.dart';
import 'package:wallet_app/data/repositories/transaction_repository.dart';
import 'package:wallet_app/core/services/app_events.dart';
import 'package:wallet_app/presentation/transactions/bloc/transactions_bloc.dart';
import 'package:wallet_app/presentation/transactions/bloc/transaction_filter.dart';
import 'package:wallet_app/presentation/transactions/pages/transaction_detail_page.dart';

class MockTransactionRepository extends Mock
    implements TransactionRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockTagRepository extends Mock implements TagRepository {}

class MockTransactionsBloc extends MockBloc<TransactionsEvent, TransactionsState>
    implements TransactionsBloc {}

// Sabit test işlemleri
final _manualTx = TransactionModel(
  id: 'tx-manual',
  amount: 150.0,
  type: TransactionType.EXPENSE,
  source: TransactionSource.MANUAL,
  date: DateTime(2026, 5, 1),
);

final _recurringTx = TransactionModel(
  id: 'tx-recurring',
  amount: 500.0,
  type: TransactionType.EXPENSE,
  source: TransactionSource.RECURRING,
  date: DateTime(2026, 5, 1),
);

final _debtPaymentTx = TransactionModel(
  id: 'tx-debt',
  amount: 1000.0,
  type: TransactionType.EXPENSE,
  source: TransactionSource.DEBT_PAYMENT,
  date: DateTime(2026, 5, 1),
);

Widget _wrap(TransactionModel tx, MockTransactionsBloc bloc) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('tr'), Locale('en')],
    home: BlocProvider<TransactionsBloc>.value(
      value: bloc,
      child: TransactionDetailPage(transaction: tx),
    ),
  );
}

void main() {
  late MockTransactionsBloc bloc;
  late MockTransactionRepository txRepo;
  late MockCategoryRepository catRepo;
  late MockAccountRepository accRepo;
  late MockTagRepository tagRepo;

  setUpAll(() {
    registerFallbackValue(TransactionDeleteRequested(''));
  });

  setUp(() {
    bloc = MockTransactionsBloc();
    txRepo = MockTransactionRepository();
    catRepo = MockCategoryRepository();
    accRepo = MockAccountRepository();
    tagRepo = MockTagRepository();

    // GetIt mock kaydı
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<TransactionRepository>()) {
      getIt.registerLazySingleton<TransactionRepository>(() => txRepo);
    }
    if (!getIt.isRegistered<CategoryRepository>()) {
      getIt.registerLazySingleton<CategoryRepository>(() => catRepo);
    }
    if (!getIt.isRegistered<AccountRepository>()) {
      getIt.registerLazySingleton<AccountRepository>(() => accRepo);
    }
    if (!getIt.isRegistered<TagRepository>()) {
      getIt.registerLazySingleton<TagRepository>(() => tagRepo);
    }
    if (!getIt.isRegistered<AppEvents>()) {
      getIt.registerLazySingleton<AppEvents>(() => AppEvents());
    }

    // Bloc default state
    when(() => bloc.state).thenReturn(TransactionsLoaded(
      transactions: [_manualTx],
      income: 0,
      expense: 150,
      net: -150,
      filter: TransactionFilter.empty,
    ));
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('TransactionDetailPage — Düzenle/Sil ikonu görünürlüğü', () {
    testWidgets(
        'MANUAL işlemde Düzenle (edit_outlined) ikonu görünür',
        (tester) async {
      await tester.pumpWidget(_wrap(_manualTx, bloc));
      await tester.pump();

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets(
        'RECURRING işlemde Düzenle ikonu görünmez',
        (tester) async {
      await tester.pumpWidget(_wrap(_recurringTx, bloc));
      await tester.pump();

      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets(
        'DEBT_PAYMENT işlemde Düzenle ikonu görünmez',
        (tester) async {
      await tester.pumpWidget(_wrap(_debtPaymentTx, bloc));
      await tester.pump();

      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets(
        'MANUAL işlemde Sil (delete_outline_rounded) ikonu görünür',
        (tester) async {
      await tester.pumpWidget(_wrap(_manualTx, bloc));
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets(
        'RECURRING işlemde Sil ikonu görünmez (salt-okunur)',
        (tester) async {
      await tester.pumpWidget(_wrap(_recurringTx, bloc));
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });

    testWidgets(
        'DEBT_PAYMENT işlemde Sil ikonu görünmez (salt-okunur)',
        (tester) async {
      await tester.pumpWidget(_wrap(_debtPaymentTx, bloc));
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });
  });
}
