import 'package:algo_erp_front/features/organization_user/domain/user_credentials.dart';
import 'package:equatable/equatable.dart';

sealed class UserCredentialsFormEvent extends Equatable {
  const UserCredentialsFormEvent();

  @override
  List<Object?> get props => [];
}

final class UserCredentialsFormInitialized extends UserCredentialsFormEvent {
  const UserCredentialsFormInitialized({this.entityId});
  final int? entityId;

  @override
  List<Object?> get props => [entityId];
}

final class UserCredentialsFormEntityUpdated extends UserCredentialsFormEvent {
  const UserCredentialsFormEntityUpdated(this.entity);
  final UserCredentials entity;

  @override
  List<Object?> get props => [entity];
}

final class UserCredentialsFormSubmitted extends UserCredentialsFormEvent {
  const UserCredentialsFormSubmitted();
}

final class UserCredentialsFormDeleted extends UserCredentialsFormEvent {
  const UserCredentialsFormDeleted();
}
