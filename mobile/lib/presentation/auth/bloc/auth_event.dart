part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class RegisterRequested extends AuthEvent {
  const RegisterRequested({
    required this.fullName,
    required this.email,
    required this.password,
  });
  final String fullName;
  final String email;
  final String password;

  @override
  List<Object?> get props => [fullName, email, password];
}

final class ForgotPasswordRequested extends AuthEvent {
  const ForgotPasswordRequested({required this.email});
  final String email;

  @override
  List<Object?> get props => [email];
}

final class VerifyResetCodeRequested extends AuthEvent {
  const VerifyResetCodeRequested({required this.token});
  final String token;

  @override
  List<Object?> get props => [token];
}

final class ResetPasswordRequested extends AuthEvent {
  const ResetPasswordRequested({
    required this.token,
    required this.newPassword,
  });
  final String token;
  final String newPassword;

  @override
  List<Object?> get props => [token, newPassword];
}

final class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

final class BiometricAuthRequested extends AuthEvent {
  const BiometricAuthRequested();
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
