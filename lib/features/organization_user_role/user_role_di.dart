import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_user_role/data/user_role_dto.dart';
import 'package:algo_erp_front/features/organization_user_role/data/user_role_mapper.dart';
import 'package:algo_erp_front/features/organization_user_role/domain/user_role.dart';
import 'package:algo_erp_front/features/organization_user_role/user_role_manifest.dart';

const _userRoleMapper = UserRoleMapper();

RemoteRepository<UserRole, int> createUserRoleRepository(DioClient client) {
  return buildRepository<UserRole, int>(
    client: client,
    resourcePath: userRoleManifest.resourcePath,
    decode: (json) => _userRoleMapper.toEntity(UserRoleDto.fromJson(json)),
    encode: (role) => _userRoleMapper.toDto(role).toJson(),
    idOf: (role) => role.id,
  );
}

CrudBloc<UserRole, int, void> createUserRoleCrudBloc(DioClient client) {
  return CrudBloc<UserRole, int, void>(
    repository: createUserRoleRepository(client),
    idOf: (role) => role.id,
  );
}
