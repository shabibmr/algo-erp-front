import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:equatable/equatable.dart';

enum RolePermissionsStatus { initial, loading, success, failure }

final class RolePermissionsState extends Equatable {
  const RolePermissionsState({
    this.status = RolePermissionsStatus.initial,
    this.roleId,
    this.rows = const {},
    this.isSaving = false,
    this.saveSuccess = false,
    this.errorMessage,
    this.failure,
  });

  final RolePermissionsStatus status;
  final int? roleId;
  final Map<String, ModulePermissions> rows;
  final bool isSaving;
  final bool saveSuccess;
  final String? errorMessage;
  final Failure? failure;

  bool get isLoading => status == RolePermissionsStatus.loading;
  bool get isSuccess => status == RolePermissionsStatus.success;
  bool get isFailure => status == RolePermissionsStatus.failure;

  RolePermissionsState copyWith({
    RolePermissionsStatus? status,
    int? roleId,
    Map<String, ModulePermissions>? rows,
    bool? isSaving,
    bool? saveSuccess,
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return RolePermissionsState(
      status: status ?? this.status,
      roleId: roleId ?? this.roleId,
      rows: rows ?? this.rows,
      isSaving: isSaving ?? this.isSaving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    roleId,
    rows,
    isSaving,
    saveSuccess,
    errorMessage,
    failure,
  ];
}
