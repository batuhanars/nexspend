part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthFailure extends AuthState {
  const AuthFailure({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

final class ForgotPasswordSuccess extends AuthState {
  const ForgotPasswordSuccess({required this.email});
  final String email;

  @override
  List<Object?> get props => [email];
}

final class ResetPasswordSuccess extends AuthState {
  const ResetPasswordSuccess();
}
