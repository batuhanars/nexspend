import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:wallet_app/data/models/transaction_model.dart';
import 'package:wallet_app/presentation/transactions/bloc/transaction_filter.dart';
import 'package:wallet_app/presentation/transactions/bloc/transactions_bloc.dart';
import 'package:wallet_app/presentation/transactions/widgets/transaction_tile.dart';

class MockTransactionsBloc extends MockBloc<TransactionsEvent, TransactionsState>
    implements TransactionsBloc {}

// Seed state yardımcısı
TransactionsLoaded _loadedWith({
  required List<TransactionModel> transactions,
  bool selectionMode = false,
  Set<String> selectedIds = const {},
}) =>
    TransactionsLoaded(
      transactions: transactions,
      income: 0,
      expense: 0,
      net: 0,
      filter: TransactionFilter.empty,
      selectionMode: selectionMode,
      selectedIds: selectedIds,
    );

TransactionModel _manual(String id) => TransactionModel(
      id: id,
      amount: 100,
      type: TransactionType.EXPENSE,
      source: TransactionSource.MANUAL,
      date: DateTime(2026, 5, 1),
    );

TransactionModel _recurring(String id) => TransactionModel(
      id: id,
      amount: 50,
      type: TransactionType.EXPENSE,
      source: TransactionSource.RECURRING,
      date: DateTime(2026, 5, 2),
    );

Widget _buildTile({
  required TransactionModel transaction,
  required TransactionsBloc bloc,
  bool selectionMode = false,
  bool isSelected = false,
  VoidCallback? onLongPress,
  VoidCallback? onTapInSelection,
}) {
  return MaterialApp(
    locale: const Locale('tr'),
    supportedLocales: const [Locale('tr'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: BlocProvider<TransactionsBloc>.value(
        value: bloc,
        child: TransactionTile(
          transaction: transaction,
          selectionMode: selectionMode,
          isSelected: isSelected,
          onLongPress: onLongPress,
          onTapInSelection: onTapInSelection,
        ),
      ),
    ),
  );
}

void main() {
  late MockTransactionsBloc bloc;

  setUp(() {
    bloc = MockTransactionsBloc();
    when(() => bloc.state).thenReturn(
      _loadedWith(transactions: [_manual('m1')]),
    );
    when(() => bloc.stream).thenAnswer(
      (_) => const Stream.empty(),
    );
  });

  group('TransactionTile — normal mod', () {
    testWidgets('Long-press → SelectionModeEntered event eklenir', (tester) async {
      SelectionModeEntered? captured;

      await tester.pumpWidget(_buildTile(
        transaction: _manual('m1'),
        bloc: bloc,
        selectionMode: false,
        onLongPress: () => captured = SelectionModeEntered(initialId: 'm1'),
      ));

      await tester.longPress(find.byType(InkWell).first);
      await tester.pump();

      expect(captured?.initialId, equals('m1'));
    });
  });

  group('TransactionTile — seçim modu', () {
    testWidgets('Seçili MANUAL tile\'a tap → SelectionToggled eklenir',
        (tester) async {
      SelectionToggled? captured;

      await tester.pumpWidget(_buildTile(
        transaction: _manual('m1'),
        bloc: bloc,
        selectionMode: true,
        isSelected: false,
        onTapInSelection: () => captured = SelectionToggled('m1'),
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(captured?.id, equals('m1'));
    });

    testWidgets(
        'Otomatik tile\'a tap → SelectionToggled eklenmez, snackbar gösterilir',
        (tester) async {
      SelectionToggled? captured;

      await tester.pumpWidget(_buildTile(
        transaction: _recurring('a1'),
        bloc: bloc,
        selectionMode: true,
        isSelected: false,
        onTapInSelection: () => captured = SelectionToggled('a1'),
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      // SelectionToggled gönderilmemeli (tile widget'ı otomatik işlem için
      // onTapInSelection'ı çağırmaz; snackbar gösterir)
      expect(captured, isNull);

      // Snackbar mesajı görünmeli (TR locale'de)
      expect(
        find.text('Otomatik oluşturulan işlemler seçilemez.'),
        findsOneWidget,
      );
    });

    testWidgets('Seçili MANUAL tile\'da check ikonu görünür', (tester) async {
      await tester.pumpWidget(_buildTile(
        transaction: _manual('m1'),
        bloc: bloc,
        selectionMode: true,
        isSelected: true,
      ));

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
