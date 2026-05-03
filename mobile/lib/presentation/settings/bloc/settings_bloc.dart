import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required UserRepository userRepository,
    required SecureStorage storage,
  })  : _repo = userRepository,
        _storage = storage,
        super(SettingsInitial()) {
    on<SettingsLoadRequested>(_onLoad);
    on<SettingsProfileUpdated>(_onProfileUpdated);
    on<SettingsPasswordChanged>(_onPasswordChanged);
    on<SettingsAvatarUploaded>(_onAvatarUploaded);
    on<SettingsAvatarDeleted>(_onAvatarDeleted);
    on<SettingsToggleChanged>(_onToggleChanged);
  }

  final UserRepository _repo;
  final SecureStorage _storage;

  Future<void> _onLoad(
      SettingsLoadRequested event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    try {
      final user = await _repo.getMe();
      emit(SettingsLoaded(user: user));
    } catch (e) {
      emit(SettingsError(_parseError(e)));
    }
  }

  Future<void> _onProfileUpdated(
      SettingsProfileUpdated event, Emitter<SettingsState> emit) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    emit(SettingsSaving(user: current.user));
    try {
      final updated = await _repo.updateMe(event.data);
      emit(SettingsLoaded(user: updated, successMessage: 'Profil güncellendi'));
    } catch (e) {
      emit(SettingsLoaded(
          user: current.user, errorMessage: _parseError(e)));
    }
  }

  Future<void> _onPasswordChanged(
      SettingsPasswordChanged event, Emitter<SettingsState> emit) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    emit(SettingsSaving(user: current.user));
    try {
      await _repo.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(SettingsLoaded(
          user: current.user, successMessage: 'Şifre güncellendi'));
    } catch (e) {
      emit(SettingsLoaded(
          user: current.user, errorMessage: _parsePasswordError(e)));
    }
  }

  Future<void> _onAvatarUploaded(
      SettingsAvatarUploaded event, Emitter<SettingsState> emit) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    emit(SettingsSaving(user: current.user));
    try {
      final updated = await _repo.uploadAvatar(event.filePath);
      emit(SettingsLoaded(user: updated));
    } catch (e) {
      emit(SettingsLoaded(user: current.user, errorMessage: _parseError(e)));
    }
  }

  Future<void> _onAvatarDeleted(
      SettingsAvatarDeleted event, Emitter<SettingsState> emit) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    emit(SettingsSaving(user: current.user));
    try {
      await _repo.deleteAvatar();
      emit(SettingsLoaded(user: current.user.copyWith(clearAvatar: true)));
    } catch (e) {
      emit(SettingsLoaded(user: current.user, errorMessage: _parseError(e)));
    }
  }

  Future<void> _onToggleChanged(
      SettingsToggleChanged event, Emitter<SettingsState> emit) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    // Optimistic update
    final optimistic = current.user.copyWith(
      biometricEnabled: event.field == 'biometric' ? event.value : null,
      notificationsEnabled:
          event.field == 'notifications' ? event.value : null,
    );
    emit(SettingsLoaded(user: optimistic));
    try {
      final updated =
          await _repo.updateMe({event.field == 'biometric' ? 'biometricEnabled' : 'notificationsEnabled': event.value});
      if (event.field == 'biometric') {
        await _storage.saveBiometricEnabled(event.value);
      }
      emit(SettingsLoaded(user: updated));
    } catch (_) {
      emit(SettingsLoaded(user: current.user));
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException')) return 'İnternet bağlantınızı kontrol edin.';
    return 'İşlem gerçekleştirilemedi.';
  }

  String _parsePasswordError(Object e) {
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('400')) return 'Mevcut şifre hatalı.';
    return _parseError(e);
  }
}
