import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/organization_user/data/user_credentials_dto.dart';
import 'package:algo_erp_front/features/organization_user/domain/user_credentials.dart';

class UserCredentialsMapper
    implements Mapper<UserCredentialsDto, UserCredentials> {
  const UserCredentialsMapper();

  @override
  UserCredentials toEntity(UserCredentialsDto dto) => UserCredentials(
    id: dto.id,
    username: dto.username,
    contactId: dto.contactId,
    roleId: dto.roleId,
    branchId: dto.branchId,
    employeeId: dto.employeeId,
    isActive: dto.isActive,
  );

  @override
  UserCredentialsDto toDto(UserCredentials entity) => UserCredentialsDto(
    id: entity.id,
    username: entity.username,
    contactId: entity.contactId,
    roleId: entity.roleId,
    password: entity.password,
    branchId: entity.branchId,
    employeeId: entity.employeeId,
    isActive: entity.isActive,
  );
}
