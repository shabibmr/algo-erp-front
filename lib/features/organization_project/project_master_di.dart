import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_project/data/project_master_dto.dart';
import 'package:algo_erp_front/features/organization_project/data/project_master_mapper.dart';
import 'package:algo_erp_front/features/organization_project/domain/project_master.dart';
import 'package:flutter/widgets.dart';

const _projectMasterMapper = ProjectMasterMapper();

/// Path kept as a literal so the selfFk parent picker can import this file
/// without a circular import on the manifest.
const projectMasterResourcePath = '/organization/projects';

RemoteRepository<ProjectMaster, int> createProjectMasterRepository(
  DioClient client,
) {
  return buildRepository<ProjectMaster, int>(
    client: client,
    resourcePath: projectMasterResourcePath,
    decode: (json) =>
        _projectMasterMapper.toEntity(ProjectMasterDto.fromJson(json)),
    encode: (project) => _projectMasterMapper.toDto(project).toJson(),
    idOf: (project) => project.id,
  );
}

CrudBloc<ProjectMaster, int, void> createProjectMasterCrudBloc(
  DioClient client,
) {
  return CrudBloc<ProjectMaster, int, void>(
    repository: createProjectMasterRepository(client),
    idOf: (project) => project.id,
  );
}

CrudBloc<ProjectMaster, int, void> projectMasterCrudBloc(BuildContext context) {
  return CrudBlocScope.of<ProjectMaster, int, void>(
    context,
    projectMasterResourcePath,
    () => createProjectMasterCrudBloc(getIt<DioClient>()),
  );
}
