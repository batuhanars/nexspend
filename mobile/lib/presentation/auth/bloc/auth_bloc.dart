import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/local_auth_service.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
    required LocalAuthService localAuthService,
  })  : _authRepository = authRepository,
        _localAuthService = localAuthService,
        super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<BiometricAuthRequested>(_onBiometricAuthRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _authRepository;
  final LocalAuthService _localAuthService;

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthFailure(message: _parseError(e)));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.register(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
      );
      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthFailure(message: _parseError(e)));
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.forgotPassword(email: event.email);
      emit(ForgotPasswordSuccess(email: event.email));
    } catch (e) {
      emit(AuthFailure(message: _parseError(e)));
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.resetPassword(
        token: event.token,
        newPassword: event.newPassword,
      );
      emit(const ResetPasswordSuccess());
    } catch (e) {
      emit(AuthFailure(message: _parseError(e)));
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.googleSignIn();
      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthFailure(message: _parseError(e)));
    }
  }

  Future<void> _onBiometricAuthRequested(
    BiometricAuthRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final success = await _localAuthService.authenticate();
      if (success) {
        emit(const AuthAuthenticated());
      } else {
        emit(const AuthInitial());
      }
    } catch (e) {
      emit(AuthFailure(message: _parseError(e)));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('credentials')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (msg.contains('409') || msg.contains('already exists')) {
      return 'Bu e-posta adresi zaten kullanılıyor.';
    }
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Bağlantı hatası. İnternet bağlantınızı kontrol edin.';
    }
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}
