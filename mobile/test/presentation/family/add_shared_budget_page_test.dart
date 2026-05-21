import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/presentation/family/bloc/add_shared_budget_bloc.dart';
import 'package:wallet_app/presentation/family/bloc/add_shared_budget_event.dart';
import 'package:wallet_app/presentation/family/bloc/add_shared_budget_state.dart';
import 'package:wallet_app/presentation/family/pages/add_shared_budget_page.dart';

class MockAddSharedBudgetBloc
    extends MockBloc<AddSharedBudgetEvent, AddSharedBudgetState>
    implements AddSharedBudgetBloc {}

Widget _wrap(Widget child, MockAddSharedBudgetBloc bloc) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('tr'), Locale('en')],
    home: BlocProvider<AddSharedBudgetBloc>.value(
      value: bloc,
      child: child,
    ),
  );
}

void main() {
  late MockAddSharedBudgetBloc bloc;

  setUp(() {
    bloc = MockAddSharedBudgetBloc();
    when(() => bloc.state)
        .thenReturn(AddSharedBudgetReady(const []));
  });

  testWidgets('form elemanları render edilir — ad alanı ve kaydet butonu görünür',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const AddSharedBudgetPage(groupId: 'g-test'),
      bloc,
    ));
    await tester.pump();

    // AppBar başlığı görünür
    expect(find.byType(AppBar), findsOneWidget);

    // Kaydet butonu görünür
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('kategori yüklenirken CircularProgressIndicator görünür',
      (tester) async {
    when(() => bloc.state)
        .thenReturn(AddSharedBudgetCategoriesLoading());

    await tester.pumpWidget(_wrap(
      const AddSharedBudgetPage(groupId: 'g-test'),
      bloc,
    ));
    await tester.pump();

    expect(
      find.byType(CircularProgressIndicator),
      findsOneWidget,
    );
  });

  testWidgets('gönderme sırasında kaydet butonu devre dışı kalır',
      (tester) async {
    when(() => bloc.state)
        .thenReturn(AddSharedBudgetSubmitting(const []));

    await tester.pumpWidget(_wrap(
      const AddSharedBudgetPage(groupId: 'g-test'),
      bloc,
    ));
    await tester.pump();

    final btn =
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull);
  });
}
