import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/organization_user_role/data/user_role_dto.dart';
import 'package:algo_erp_front/features/organization_user_role/domain/user_role.dart';

class UserRoleMapper implements Mapper<UserRoleDto, UserRole> {
  const UserRoleMapper();

  @override
  UserRole toEntity(UserRoleDto dto) => UserRole(
        id: dto.id,
        name: dto.roleName,
        description: dto.description,
      );

  @override
  UserRoleDto toDto(UserRole entity) => UserRoleDto(
        id: entity.id,
        roleName: entity.name,
        description: entity.description,
      );
}
