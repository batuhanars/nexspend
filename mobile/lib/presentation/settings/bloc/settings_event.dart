part of 'settings_bloc.dart';

sealed class SettingsEvent {
  const SettingsEvent();
}

class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

class SettingsProfileUpdated extends SettingsEvent {
  const SettingsProfileUpdated(this.data);
  final Map<String, dynamic> data;
}

class SettingsPasswordChanged extends SettingsEvent {
  const SettingsPasswordChanged({
    required this.currentPassword,
    required this.newPassword,
  });
  final String currentPassword;
  final String newPassword;
}

class SettingsAvatarUploaded extends SettingsEvent {
  const SettingsAvatarUploaded(this.filePath);
  final String filePath;
}

class SettingsAvatarDeleted extends SettingsEvent {
  const SettingsAvatarDeleted();
}

class SettingsToggleChanged extends SettingsEvent {
  const SettingsToggleChanged({required this.field, required this.value});
  final String field;
  final bool value;
}

class SettingsResetRequested extends SettingsEvent {
  const SettingsResetRequested();
}
