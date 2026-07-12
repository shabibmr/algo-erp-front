import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/employee_employee/data/employee_dto.dart';
import 'package:algo_erp_front/features/employee_employee/data/employee_mapper.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:algo_erp_front/features/employee_employee/employee_manifest.dart';
import 'package:flutter/widgets.dart';

const _employeeMapper = EmployeeMapper();

RemoteRepository<Employee, int> createEmployeeRepository(DioClient client) {
  return buildRepository<Employee, int>(
    client: client,
    resourcePath: employeeManifest.resourcePath,
    decode: (json) => _employeeMapper.toEntity(EmployeeDto.fromJson(json)),
    encode: (e) => _employeeMapper.toDto(e).toJson(),
    idOf: (e) => e.id,
  );
}

CrudBloc<Employee, int, void> createEmployeeCrudBloc(DioClient client) {
  return CrudBloc<Employee, int, void>(
    repository: createEmployeeRepository(client),
    idOf: (e) => e.id,
  );
}

CrudBloc<Employee, int, void> employeeCrudBloc(BuildContext context) {
  return CrudBlocScope.of<Employee, int, void>(
    context,
    employeeManifest.id,
    () => createEmployeeCrudBloc(getIt<DioClient>()),
  );
}
