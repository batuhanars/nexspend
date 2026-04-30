part of 'account_bloc.dart';

sealed class AccountEvent {}

class AccountCreateRequested extends AccountEvent {
  AccountCreateRequested(this.data);
  final Map<String, dynamic> data;
}
