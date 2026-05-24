import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/data/models/account_model.dart';
import 'package:wallet_app/data/models/category_model.dart';
import 'package:wallet_app/presentation/transactions/bloc/transaction_filter.dart';
import 'package:wallet_app/presentation/transactions/widgets/transaction_filter_sheet.dart';

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

Widget _wrapSheet({
  required TransactionFilter initialFilter,
  required ValueChanged<TransactionFilter> onApply,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('tr'), Locale('en')],
    locale: const Locale('tr'),
    home: Scaffold(
      body: TransactionFilterSheet(
        initialFilter: initialFilter,
        categories: [_cat1],
        accounts: [_acc1],
        onApply: onApply,
      ),
    ),
  );
}

void main() {
  group('TransactionFilterSheet', () {
    testWidgets('sheet render: kategori ve hesap chip\'leri görünür',
        (tester) async {
      await tester.pumpWidget(_wrapSheet(
        initialFilter: TransactionFilter.empty,
        onApply: (_) {},
      ));
      await tester.pumpAndSettle();

      // Kategori chip'i
      expect(find.text('Market'), findsOneWidget);
      // Hesap chip'i
      expect(find.text('Ziraat'), findsOneWidget);
    });

    testWidgets('Uygula → onApply callback kategori seçimiyle tetiklenir',
        (tester) async {
      TransactionFilter? applied;
      await tester.pumpWidget(_wrapSheet(
        initialFilter: TransactionFilter.empty,
        onApply: (f) => applied = f,
      ));
      await tester.pumpAndSettle();

      // Kategori chip'ine tıkla
      await tester.tap(find.text('Market'));
      await tester.pump();

      // Uygula butonuna tıkla (TR locale)
      await tester.tap(find.text('Uygula'));
      await tester.pump();

      expect(applied, isNotNull);
      expect(applied!.categoryId, 'cat-1');
    });

    testWidgets('Uygula → onApply callback hesap seçimiyle tetiklenir',
        (tester) async {
      TransactionFilter? applied;
      await tester.pumpWidget(_wrapSheet(
        initialFilter: TransactionFilter.empty,
        onApply: (f) => applied = f,
      ));
      await tester.pumpAndSettle();

      // Hesap chip'ine tıkla
      await tester.tap(find.text('Ziraat'));
      await tester.pump();

      // Uygula
      await tester.tap(find.text('Uygula'));
      await tester.pump();

      expect(applied, isNotNull);
      expect(applied!.accountId, 'acc-1');
    });

    testWidgets('Temizle → tüm filtreler sıfırlanır, Uygula → boş filter',
        (tester) async {
      TransactionFilter? applied;
      await tester.pumpWidget(_wrapSheet(
        initialFilter: const TransactionFilter(
          categoryId: 'cat-1',
          accountId: 'acc-1',
        ),
        onApply: (f) => applied = f,
      ));
      await tester.pumpAndSettle();

      // Temizle butonuna tıkla
      await tester.tap(find.text('Temizle'));
      await tester.pump();

      // Uygula
      await tester.tap(find.text('Uygula'));
      await tester.pump();

      expect(applied, isNotNull);
      expect(applied!.categoryId, isNull);
      expect(applied!.accountId, isNull);
      expect(applied!.startDate, isNull);
      expect(applied!.endDate, isNull);
    });

    testWidgets('Bu Ay preset chip\'i seçilince startDate ayın 1\'i olur',
        (tester) async {
      TransactionFilter? applied;
      await tester.pumpWidget(_wrapSheet(
        initialFilter: TransactionFilter.empty,
        onApply: (f) => applied = f,
      ));
      await tester.pumpAndSettle();

      // "Bu Ay" chip'ine tıkla
      await tester.tap(find.text('Bu Ay'));
      await tester.pump();

      // Uygula
      await tester.tap(find.text('Uygula'));
      await tester.pump();

      expect(applied, isNotNull);
      expect(applied!.startDate, isNotNull);
      expect(applied!.startDate!.day, 1);
      final now = DateTime.now();
      expect(applied!.startDate!.month, now.month);
    });
  });
}
