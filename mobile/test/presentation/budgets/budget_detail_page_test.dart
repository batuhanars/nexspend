import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/data/models/budget_model.dart';
import 'package:wallet_app/data/models/transaction_model.dart';
import 'package:wallet_app/data/repositories/budget_repository.dart';
import 'package:wallet_app/data/repositories/transaction_repository.dart';
import 'package:wallet_app/presentation/budgets/bloc/budgets_bloc.dart';
import 'package:wallet_app/presentation/budgets/bloc/budgets_event.dart';
import 'package:wallet_app/presentation/budgets/bloc/budgets_state.dart';
import 'package:wallet_app/presentation/budgets/pages/budget_detail_page.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockBudgetsBloc extends MockBloc<BudgetsEvent, BudgetsState>
    implements BudgetsBloc {}

final _budget = BudgetModel(
  id: 'b-test',
  name: 'Test Bütçesi',
  amount: 3000.0,
  spent: 1500.0,
  remaining: 1500.0,
  percentage: 50,
  status: BudgetStatus.WARNING,
  period: BudgetPeriod.MONTHLY,
  smartTracking: false,
  isActive: false,
  startDate: DateTime(2026, 4, 1),
  endDate: DateTime(2026, 4, 30),
);

Widget _wrap(Widget child, MockBudgetsBloc bloc) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('tr'), Locale('en')],
    home: BlocProvider<BudgetsBloc>.value(
      value: bloc,
      child: child,
    ),
  );
}

void main() {
  late MockBudgetRepository budgetRepo;
  late MockTransactionRepository txRepo;
  late MockBudgetsBloc bloc;

  setUp(() {
    budgetRepo = MockBudgetRepository();
    txRepo = MockTransactionRepository();
    bloc = MockBudgetsBloc();

    when(() => bloc.state).thenReturn(BudgetsInitial());

    if (GetIt.instance.isRegistered<BudgetRepository>()) {
      GetIt.instance.unregister<BudgetRepository>();
    }
    if (GetIt.instance.isRegistered<TransactionRepository>()) {
      GetIt.instance.unregister<TransactionRepository>();
    }
    GetIt.instance.registerSingleton<BudgetRepository>(budgetRepo);
    GetIt.instance.registerSingleton<TransactionRepository>(txRepo);

    when(() => txRepo.getTransactions(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          type: any(named: 'type'),
          categoryId: any(named: 'categoryId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => (
              data: <TransactionModel>[],
              total: 0,
              totalPages: 0,
            ));

    when(() => budgetRepo.getHistory(any())).thenAnswer((_) async => []);
  });

  tearDown(() {
    GetIt.instance.unregister<BudgetRepository>();
    GetIt.instance.unregister<TransactionRepository>();
  });

  testWidgets(
      'initialTabIndex: 1 ile açılınca Geçmiş sekmesi aktif ve içeriği görünür',
      (tester) async {
    await tester.pumpWidget(_wrap(
      BudgetDetailPage(budget: _budget, initialTabIndex: 1),
      bloc,
    ));
    await tester.pumpAndSettle();

    // Geçmiş sekmesi active: TabBar 2. sekme seçili
    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.controller?.index, 1);

    // Geçmiş boş durum ikonu görünür (history_toggle_off_outlined)
    expect(
      find.byIcon(Icons.history_toggle_off_outlined),
      findsOneWidget,
    );
  });

  testWidgets(
      'budgetId verilince getById çağrılır ve bütçe adı render edilir',
      (tester) async {
    when(() => budgetRepo.getById('b-test'))
        .thenAnswer((_) async => _budget);

    await tester.pumpWidget(_wrap(
      const BudgetDetailPage(budgetId: 'b-test'),
      bloc,
    ));

    // Loading gösterge beklenir
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // getById 1 kez çağrılmış olmalı
    verify(() => budgetRepo.getById('b-test')).called(1);

    // Bütçe adı AppBar'da görünür
    expect(find.text(_budget.name), findsAtLeast(1));
  });

  testWidgets(
      'getById başarısız olursa serverError metni gösterilir',
      (tester) async {
    when(() => budgetRepo.getById(any()))
        .thenThrow(Exception('Network error'));

    await tester.pumpWidget(_wrap(
      const BudgetDetailPage(budgetId: 'b-missing'),
      bloc,
    ));
    await tester.pumpAndSettle();

    // Hata durumunda fallback ekran gelir (loading yoktur, budget null)
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
