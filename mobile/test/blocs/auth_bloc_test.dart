import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/services/local_auth_service.dart';
import 'package:wallet_app/data/repositories/auth_repository.dart';
import 'package:wallet_app/presentation/auth/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockLocalAuthService extends Mock implements LocalAuthService {}

void main() {
  late MockAuthRepository repo;
  late MockLocalAuthService localAuth;

  setUp(() {
    repo = MockAuthRepository();
    localAuth = MockLocalAuthService();
  });

  AuthBloc buildBloc() => AuthBloc(
        authRepository: repo,
        localAuthService: localAuth,
      );

  group('LoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'başarılı girişte Loading → Authenticated',
      build: () {
        when(() => repo.login(email: 'test@test.com', password: '123456'))
            .thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        LoginRequested(email: 'test@test.com', password: '123456'),
      ),
      expect: () => [const AuthLoading(), const AuthAuthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      '401 hatasında Loading → AuthFailure (yanlış şifre mesajı)',
      build: () {
        when(() => repo.login(email: any(named: 'email'), password: any(named: 'password')))
            .thenThrow(Exception('401 credentials'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        LoginRequested(email: 'x@x.com', password: 'wrong'),
      ),
      expect: () => [
        const AuthLoading(),
        isA<AuthFailure>()
            .having((s) => s.message, 'mesaj', contains('E-posta veya şifre')),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'ağ hatasında Loading → AuthFailure (bağlantı mesajı)',
      build: () {
        when(() => repo.login(email: any(named: 'email'), password: any(named: 'password')))
            .thenThrow(Exception('SocketException'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        LoginRequested(email: 'x@x.com', password: '123456'),
      ),
      expect: () => [
        const AuthLoading(),
        isA<AuthFailure>()
            .having((s) => s.message, 'mesaj', contains('Bağlantı')),
      ],
    );
  });

  group('RegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'başarılı kayıtta Loading → Authenticated',
      build: () {
        when(() => repo.register(
              fullName: any(named: 'fullName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        RegisterRequested(
          fullName: 'Test Kullanıcı',
          email: 'new@test.com',
          password: '123456',
        ),
      ),
      expect: () => [const AuthLoading(), const AuthAuthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'e-posta zaten kayıtlıysa Loading → AuthFailure (409 mesajı)',
      build: () {
        when(() => repo.register(
              fullName: any(named: 'fullName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(Exception('409 already exists'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        RegisterRequested(
          fullName: 'Test',
          email: 'exists@test.com',
          password: '123456',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        isA<AuthFailure>()
            .having((s) => s.message, 'mesaj', contains('zaten kullanılıyor')),
      ],
    );
  });

  group('ForgotPasswordRequested', () {
    blocTest<AuthBloc, AuthState>(
      'başarılı sıfırlamada Loading → ForgotPasswordSuccess (e-posta adresi döner)',
      build: () {
        when(() => repo.forgotPassword(email: 'test@test.com'))
            .thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(ForgotPasswordRequested(email: 'test@test.com')),
      expect: () => [
        const AuthLoading(),
        isA<ForgotPasswordSuccess>()
            .having((s) => s.email, 'email', 'test@test.com'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'hata durumunda Loading → AuthFailure',
      build: () {
        when(() => repo.forgotPassword(email: any(named: 'email')))
            .thenThrow(Exception('not found'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(ForgotPasswordRequested(email: 'noone@test.com')),
      expect: () => [const AuthLoading(), isA<AuthFailure>()],
    );
  });

  group('ResetPasswordRequested', () {
    blocTest<AuthBloc, AuthState>(
      'başarılı sıfırlamada Loading → ResetPasswordSuccess',
      build: () {
        when(() => repo.resetPassword(
              token: 'valid-token',
              newPassword: 'newpass123',
            )).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        ResetPasswordRequested(token: 'valid-token', newPassword: 'newpass123'),
      ),
      expect: () => [const AuthLoading(), const ResetPasswordSuccess()],
    );
  });

  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'çıkışta Unauthenticated döner',
      build: () {
        when(() => repo.logout()).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(LogoutRequested()),
      expect: () => [const AuthUnauthenticated()],
    );
  });
}
