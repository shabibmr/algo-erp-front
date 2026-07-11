import 'package:equatable/equatable.dart';

/// The authenticated user, cleaned up from the wire DTO.
///
/// Carries the tenant coordinates ([branchId]/[companyId]) the backend derived
/// from the JWT, plus the [roleId]/[roleName] that RBAC keys off. [lastLoginAt]
/// is only populated by `GET /auth/me` (login itself does not return it).
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.username,
    required this.roleId,
    required this.roleName,
    this.branchId,
    this.companyId,
    this.lastLoginAt,
  });

  final int id;
  final String username;
  final int roleId;
  final String roleName;
  final int? branchId;
  final int? companyId;
  final DateTime? lastLoginAt;

  @override
  List<Object?> get props => [
    id,
    username,
    roleId,
    roleName,
    branchId,
    companyId,
    lastLoginAt,
  ];
}
