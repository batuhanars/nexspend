import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/storage/secure_storage.dart';
import 'package:wallet_app/data/models/user_model.dart';
import 'package:wallet_app/data/repositories/user_repository.dart';
import 'package:wallet_app/presentation/settings/bloc/settings_bloc.dart';
import 'package:wallet_app/presentation/settings/widgets/reset_data_sheet.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockSecureStorage extends Mock implements SecureStorage {}

const _user = UserModel(
  id: 'u-1',
  fullName: 'Test Kullanici',
  email: 'test@example.com',
  currency: 'TRY',
  language: 'tr',
  biometricEnabled: false,
  notificationsEnabled: true,
  hasPassword: true,
  isGoogleLinked: false,
);

Widget _buildSheet({required SettingsBloc bloc}) {
  return MaterialApp(
    locale: const Locale('tr'),
    supportedLocales: const [Locale('tr'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: BlocProvider.value(
        value: bloc,
        child: const ResetDataSheet(),
      ),
    ),
  );
}

void main() {
  late MockUserRepository repo;
  late MockSecureStorage storage;

  setUp(() {
    repo = MockUserRepository();
    storage = MockSecureStorage();
    when(() => repo.getMe()).thenAnswer((_) async => _user);
    when(() => storage.saveBiometricEnabled(any())).thenAnswer((_) async {});
  });

  SettingsBloc buildBloc() => SettingsBloc(
        userRepository: repo,
        storage: storage,
      );

  group('ResetDataSheet — onay butonu', () {
    testWidgets('bos textarea ile buton devre disi olmali', (tester) async {
      final bloc = buildBloc();
      bloc.emit(SettingsLoaded(user: _user));

      await tester.pumpWidget(_buildSheet(bloc: bloc));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull,
          reason: 'Bos alanda buton disabled olmali');

      bloc.close();
    });

    testWidgets('yanlis kelime girildiginde buton devre disi olmali',
        (tester) async {
      final bloc = buildBloc();
      bloc.emit(SettingsLoaded(user: _user));

      await tester.pumpWidget(_buildSheet(bloc: bloc));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'SIFIRLA_YANLIS');
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull,
          reason: 'Yanlis kelimede buton disabled olmali');

      bloc.close();
    });

    testWidgets('dogru kelime ("SIFIRLA") girildiginde buton aktif olmali',
        (tester) async {
      final bloc = buildBloc();
      bloc.emit(SettingsLoaded(user: _user));

      await tester.pumpWidget(_buildSheet(bloc: bloc));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'SIFIRLA');
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull,
          reason: 'Dogru kelimede buton aktif olmali');

      bloc.close();
    });

    testWidgets('kucuk harf girildiginde buton devre disi olmali',
        (tester) async {
      final bloc = buildBloc();
      bloc.emit(SettingsLoaded(user: _user));

      await tester.pumpWidget(_buildSheet(bloc: bloc));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'sifirla');
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull,
          reason: 'Kucuk harf ile buton disabled olmali');

      bloc.close();
    });
  });
}
