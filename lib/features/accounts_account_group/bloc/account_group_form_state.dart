import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/accounts_account_group/domain/account_group.dart';
import 'package:equatable/equatable.dart';

enum AccountGroupFormStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

final class AccountGroupFormState extends Equatable {
  const AccountGroupFormState({
    this.status = AccountGroupFormStatus.initial,
    this.entityId,
    this.isEdit = false,
    this.name = '',
    this.code = '',
    this.parentGroupId,
    this.availableGroups = const [],
    this.errorMessage,
    this.failure,
  });

  final AccountGroupFormStatus status;
  final int? entityId;
  final bool isEdit;
  final String name;
  final String code;
  final int? parentGroupId;
  final List<AccountGroup> availableGroups;
  final String? errorMessage;
  final Failure? failure;

  bool get isLoading => status == AccountGroupFormStatus.loading;
  bool get isSubmitting => status == AccountGroupFormStatus.submitting;
  bool get isSuccess => status == AccountGroupFormStatus.success;

  AccountGroupFormState copyWith({
    AccountGroupFormStatus? status,
    int? entityId,
    bool? isEdit,
    String? name,
    String? code,
    int? Function()? parentGroupId,
    List<AccountGroup>? availableGroups,
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return AccountGroupFormState(
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      isEdit: isEdit ?? this.isEdit,
      name: name ?? this.name,
      code: code ?? this.code,
      parentGroupId: parentGroupId != null
          ? parentGroupId()
          : this.parentGroupId,
      availableGroups: availableGroups ?? this.availableGroups,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entityId,
    isEdit,
    name,
    code,
    parentGroupId,
    availableGroups,
    errorMessage,
    failure,
  ];
}
