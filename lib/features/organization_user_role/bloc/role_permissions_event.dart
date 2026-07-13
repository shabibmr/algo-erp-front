import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:equatable/equatable.dart';

sealed class RolePermissionsEvent extends Equatable {
  const RolePermissionsEvent();

  @override
  List<Object?> get props => [];
}

final class RolePermissionsFetchRequested extends RolePermissionsEvent {
  const RolePermissionsFetchRequested(this.roleId);
  final int roleId;

  @override
  List<Object?> get props => [roleId];
}

final class RolePermissionToggled extends RolePermissionsEvent {
  const RolePermissionToggled({
    required this.module,
    required this.action,
    required this.value,
  });

  final String module;
  final PermissionAction action;
  final bool value;

  @override
  List<Object?> get props => [module, action, value];
}

final class RolePermissionsSaved extends RolePermissionsEvent {
  const RolePermissionsSaved();
}
