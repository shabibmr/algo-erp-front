import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/employee_department/data/department_dto.dart';
import 'package:algo_erp_front/features/employee_department/data/department_mapper.dart';
import 'package:algo_erp_front/features/employee_department/department_manifest.dart';
import 'package:algo_erp_front/features/employee_department/domain/department.dart';
import 'package:flutter/widgets.dart';

/// Plain factory functions, matching Brand's precedent — see `brand_di.dart`.
const _departmentMapper = DepartmentMapper();

RemoteRepository<Department, int> createDepartmentRepository(DioClient client) {
  return buildRepository<Department, int>(
    client: client,
    resourcePath: departmentManifest.resourcePath,
    decode: (json) => _departmentMapper.toEntity(DepartmentDto.fromJson(json)),
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

/// The one Department [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this —
/// resolving the bloc any other way gives the form a private instance the
/// list never sees, which is how created rows went missing.
CrudBloc<Department, int, void> departmentCrudBloc(BuildContext context) {
  return CrudBlocScope.of<Department, int, void>(
    context,
    departmentManifest.id,
    () => createDepartmentCrudBloc(getIt<DioClient>()),
  );
}
