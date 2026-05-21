import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/data/models/account_analytics_model.dart';
import 'package:wallet_app/presentation/accounts/widgets/this_month_section.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('tr')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('tr'), Locale('en')],
    home: Scaffold(body: child),
  );
}

AccountAnalyticsModel _standardAnalytics() => const AccountAnalyticsModel(
      months: [
        MonthlyFlowModel(
          month: '2026-05',
          income: 5000,
          expense: 2000,
        ),
      ],
      topCategories: [],
      isCreditCard: false,
    );

AccountAnalyticsModel _creditCardAnalytics() => const AccountAnalyticsModel(
      months: [
        MonthlyFlowModel(
          month: '2026-05',
          income: 0,
          expense: 0,
          payment: 1500,
          spend: 900,
        ),
      ],
      topCategories: [],
      isCreditCard: true,
    );

void main() {
  testWidgets('standart hesap — Gelir ve Gider chip etiketleri görünür',
      (tester) async {
    await tester.pumpWidget(
        _wrap(ThisMonthSection(analytics: _standardAnalytics())));
    await tester.pump();

    expect(find.text('Gelir'), findsOneWidget);
    expect(find.text('Gider'), findsOneWidget);
    expect(find.text('Ödeme'), findsNothing);
    expect(find.text('Harcama'), findsNothing);
  });

  testWidgets('kredi kartı — Ödeme ve Harcama chip etiketleri görünür',
      (tester) async {
    await tester.pumpWidget(
        _wrap(ThisMonthSection(analytics: _creditCardAnalytics())));
    await tester.pump();

    expect(find.text('Ödeme'), findsOneWidget);
    expect(find.text('Harcama'), findsOneWidget);
    expect(find.text('Gelir'), findsNothing);
    expect(find.text('Gider'), findsNothing);
  });

  testWidgets('kredi kartı — chip sayısı 2 (FlowChip)', (tester) async {
    await tester.pumpWidget(
        _wrap(ThisMonthSection(analytics: _creditCardAnalytics())));
    await tester.pump();

    expect(find.byType(FlowChip), findsNWidgets(2));
  });
}
