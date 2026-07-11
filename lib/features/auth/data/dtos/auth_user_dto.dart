import 'package:algo_erp_front/features/auth/domain/entities/auth_user.dart';
import 'package:equatable/equatable.dart';

/// Wire shape of the user object returned by `/auth/login` (`data.user`) and
/// `/auth/me` (`data`). Hand-written (no freezed) so this feature stays
/// analyzable without a build_runner pass. Field names mirror the backend
/// exactly (`roleId`, `branchId`, …); [lastLoginAt] is absent on login and
/// present on `/auth/me`, so it is nullable.
class AuthUserDto extends Equatable {
  const AuthUserDto({
    required this.id,
    required this.username,
    required this.roleId,
    required this.roleName,
    this.branchId,
    this.companyId,
    this.lastLoginAt,
  });

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: json['id'] as int,
      username: json['username'] as String,
      roleId: json['roleId'] as int,
      roleName: json['roleName'] as String? ?? '',
      branchId: json['branchId'] as int?,
      companyId: json['companyId'] as int?,
      lastLoginAt: _parseDate(json['lastLoginAt']),
    );
  }

  final int id;
  final String username;
  final int roleId;
  final String roleName;
  final int? branchId;
  final int? companyId;
  final DateTime? lastLoginAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'roleId': roleId,
    'roleName': roleName,
    'branchId': branchId,
    'companyId': companyId,
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  AuthUser toEntity() => AuthUser(
    id: id,
    username: username,
    roleId: roleId,
    roleName: roleName,
    branchId: branchId,
    companyId: companyId,
    lastLoginAt: lastLoginAt,
  );

  static DateTime? _parseDate(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;

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
