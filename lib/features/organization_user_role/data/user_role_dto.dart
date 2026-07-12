import 'package:equatable/equatable.dart';

/// Wire shape of `/organization/roles`, matching the backend `user_roles`
/// table. Field names keep the backend's original casing; the mapper produces
/// clean entity names.
class UserRoleDto extends Equatable {
  const UserRoleDto({
    required this.id,
    required this.roleName,
    this.description,
  });

  factory UserRoleDto.fromJson(Map<String, dynamic> json) => UserRoleDto(
    id: json['id'] as int,
    roleName: json['role_name'] as String,
    description: json['description'] as String?,
  );

  final int id;
  final String roleName;
  final String? description;

  /// `id`/timestamps are server-generated and never sent on write.
  Map<String, dynamic> toJson() => {
    'role_name': roleName,
    'description': description,
  };

  @override
  List<Object?> get props => [id, roleName, description];
}
