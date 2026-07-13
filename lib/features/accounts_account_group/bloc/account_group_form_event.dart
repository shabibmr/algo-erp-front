import 'package:equatable/equatable.dart';

sealed class AccountGroupFormEvent extends Equatable {
  const AccountGroupFormEvent();

  @override
  List<Object?> get props => [];
}

final class AccountGroupFormInitialized extends AccountGroupFormEvent {
  const AccountGroupFormInitialized({this.entityId});
  final int? entityId;

  @override
  List<Object?> get props => [entityId];
}

final class AccountGroupFormNameChanged extends AccountGroupFormEvent {
  const AccountGroupFormNameChanged(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}

final class AccountGroupFormCodeChanged extends AccountGroupFormEvent {
  const AccountGroupFormCodeChanged(this.code);
  final String code;

  @override
  List<Object?> get props => [code];
}

final class AccountGroupFormParentGroupIdChanged extends AccountGroupFormEvent {
  const AccountGroupFormParentGroupIdChanged(this.parentGroupId);
  final int? parentGroupId;

  @override
  List<Object?> get props => [parentGroupId];
}

final class AccountGroupFormSubmitted extends AccountGroupFormEvent {
  const AccountGroupFormSubmitted();
}
