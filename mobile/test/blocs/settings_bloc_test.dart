import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/storage/secure_storage.dart';
import 'package:wallet_app/data/models/user_model.dart';
import 'package:wallet_app/data/repositories/user_repository.dart';
import 'package:wallet_app/presentation/settings/bloc/settings_bloc.dart';

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

void main() {
  late MockUserRepository repo;
  late MockSecureStorage storage;

  setUp(() {
    repo = MockUserRepository();
    storage = MockSecureStorage();
  });

  SettingsBloc buildBloc() => SettingsBloc(
        userRepository: repo,
        storage: storage,
      );

  void stubLoadSuccess() {
    when(() => repo.getMe()).thenAnswer((_) async => _user);
    when(() => storage.saveBiometricEnabled(any())).thenAnswer((_) async {});
  }

  group('SettingsResetRequested', () {
    blocTest<SettingsBloc, SettingsState>(
      'başarılı sıfırlamada Resetting → ResetSuccess',
      build: () {
        stubLoadSuccess();
        when(() => repo.resetData()).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => SettingsLoaded(user: _user),
      act: (bloc) => bloc.add(const SettingsResetRequested()),
      expect: () => [
        isA<SettingsResetting>()
            .having((s) => s.user.id, 'user id', 'u-1'),
        isA<SettingsResetSuccess>(),
      ],
      verify: (_) {
        verify(() => repo.resetData()).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'hata durumunda Resetting → ResetFailure (kullanici korunur)',
      build: () {
        stubLoadSuccess();
        when(() => repo.resetData()).thenThrow(Exception('network error'));
        return buildBloc();
      },
      seed: () => SettingsLoaded(user: _user),
      act: (bloc) => bloc.add(const SettingsResetRequested()),
      expect: () => [
        isA<SettingsResetting>(),
        isA<SettingsResetFailure>()
            .having((s) => s.user.id, 'user id', 'u-1')
            .having((s) => s.message, 'hata mesaji', isNotEmpty),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'yuklenmemis durumda (initial) reset event yok sayilir',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const SettingsResetRequested()),
      expect: () => <SettingsState>[],
    );
  });
}
