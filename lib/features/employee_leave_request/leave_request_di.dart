import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/employee_leave_request/data/leave_request_repository.dart';
import 'package:algo_erp_front/features/employee_leave_request/domain/leave_request.dart';
import 'package:algo_erp_front/features/employee_leave_request/leave_request_manifest.dart';
import 'package:flutter/widgets.dart';

LeaveRequestRepository createLeaveRequestRepository(DioClient client) {
  return LeaveRequestRepository(client);
}

CrudBloc<LeaveRequest, int, void> createLeaveRequestCrudBloc(DioClient client) {
  return CrudBloc<LeaveRequest, int, void>(
    repository: createLeaveRequestRepository(client),
    idOf: (r) => r.id,
  );
}

CrudBloc<LeaveRequest, int, void> leaveRequestCrudBloc(BuildContext context) {
  return CrudBlocScope.of<LeaveRequest, int, void>(
    context,
    leaveRequestManifest.id,
    () => createLeaveRequestCrudBloc(getIt<DioClient>()),
  );
}
