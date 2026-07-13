import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/organization_user/domain/user_credentials.dart';
import 'package:equatable/equatable.dart';

enum UserCredentialsFormStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  deleted,
  failure,
}

final class UserCredentialsFormState extends Equatable {
  const UserCredentialsFormState({
    this.status = UserCredentialsFormStatus.initial,
    this.entityId,
    this.isEdit = false,
    this.entity,
    this.fieldErrors = const {},
    this.errorMessage,
    this.failure,
  });

  final UserCredentialsFormStatus status;
  final int? entityId;
  final bool isEdit;
  final UserCredentials? entity;
  final Map<String, String> fieldErrors;
  final String? errorMessage;
  final Failure? failure;

  UserCredentials get currentEntity =>
      entity ?? const UserCredentials(id: 0, username: '', roleId: 0);

  bool get isLoading => status == UserCredentialsFormStatus.loading;
  bool get isSubmitting => status == UserCredentialsFormStatus.submitting;
  bool get isSuccess => status == UserCredentialsFormStatus.success;
  bool get isDeleted => status == UserCredentialsFormStatus.deleted;

  UserCredentialsFormState copyWith({
    UserCredentialsFormStatus? status,
    int? entityId,
    bool? isEdit,
    UserCredentials? entity,
    Map<String, String>? fieldErrors,
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return UserCredentialsFormState(
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      isEdit: isEdit ?? this.isEdit,
      entity: entity ?? this.entity,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entityId,
    isEdit,
    entity,
    fieldErrors,
    errorMessage,
    failure,
  ];
}
