import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/employee_leave_policy/data/leave_policy_repository.dart';
import 'package:algo_erp_front/features/employee_leave_policy/domain/leave_policy.dart';
import 'package:algo_erp_front/features/employee_leave_policy/leave_policy_manifest.dart';
import 'package:flutter/widgets.dart';

Repository<LeavePolicy, int> createLeavePolicyRepository(DioClient client) {
  return LeavePolicyRepository(client);
}

CrudBloc<LeavePolicy, int, void> createLeavePolicyCrudBloc(DioClient client) {
  return CrudBloc<LeavePolicy, int, void>(
    repository: createLeavePolicyRepository(client),
    idOf: (p) => p.id,
  );
}

CrudBloc<LeavePolicy, int, void> leavePolicyCrudBloc(BuildContext context) {
  return CrudBlocScope.of<LeavePolicy, int, void>(
    context,
    leavePolicyManifest.id,
    () => createLeavePolicyCrudBloc(getIt<DioClient>()),
  );
}
