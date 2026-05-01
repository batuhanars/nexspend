part of 'account_bloc.dart';

sealed class AccountEvent {}

class AccountCreateRequested extends AccountEvent {
  AccountCreateRequested(this.data);
  final Map<String, dynamic> data;
}

class AccountUpdateRequested extends AccountEvent {
  AccountUpdateRequested({required this.id, required this.data});
  final String id;
  final Map<String, dynamic> data;
}

class AccountArchiveRequested extends AccountEvent {
  AccountArchiveRequested(this.id);
  final String id;
}

class AccountSetDefaultRequested extends AccountEvent {
  AccountSetDefaultRequested(this.id);
  final String id;
}

class AccountDeleteRequested extends AccountEvent {
  AccountDeleteRequested(this.id);
  final String id;
}

class AccountRestoreRequested extends AccountEvent {
  AccountRestoreRequested(this.id);
  final String id;
}
