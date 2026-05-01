part of 'settings_bloc.dart';

sealed class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  SettingsLoaded({
    required this.user,
    this.successMessage,
    this.errorMessage,
  });

  final UserModel user;
  final String? successMessage;
  final String? errorMessage;
}

class SettingsSaving extends SettingsState {
  SettingsSaving({required this.user});
  final UserModel user;
}

class SettingsError extends SettingsState {
  SettingsError(this.message);
  final String message;
}
