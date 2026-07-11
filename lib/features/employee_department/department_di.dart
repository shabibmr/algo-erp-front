import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/employee_department/data/department_dto.dart';
import 'package:algo_erp_front/features/employee_department/data/department_mapper.dart';
import 'package:algo_erp_front/features/employee_department/department_manifest.dart';
import 'package:algo_erp_front/features/employee_department/domain/department.dart';

/// Plain factory functions, matching Brand's precedent — see `brand_di.dart`.
const _departmentMapper = DepartmentMapper();

RemoteRepository<Department, int> createDepartmentRepository(
  DioClient client,
) {
  return buildRepository<Department, int>(
    client: client,
    resourcePath: departmentManifest.resourcePath,
    decode: (json) =>
        _departmentMapper.toEntity(DepartmentDto.fromJson(json)),
    encode: (d) => _departmentMapper.toDto(d).toJson(),
    idOf: (d) => d.id,
  );
}

CrudBloc<Department, int, void> createDepartmentCrudBloc(DioClient client) {
  return CrudBloc<Department, int, void>(
    repository: createDepartmentRepository(client),
    idOf: (d) => d.id,
  );
}
