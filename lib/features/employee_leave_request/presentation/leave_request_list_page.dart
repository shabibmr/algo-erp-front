import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/employee_leave_request/domain/leave_request.dart';
import 'package:algo_erp_front/features/employee_leave_request/leave_request_di.dart';
import 'package:algo_erp_front/features/employee_leave_request/leave_request_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LeaveRequestListPage extends StatelessWidget {
  const LeaveRequestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<LeaveRequest, int, void>>.value(
      value: leaveRequestCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<LeaveRequest>(
          manifest: leaveRequestManifest,
          idOf: (r) => r.id,
          onCreate: () => context.push('/employee/leave-requests/new'),
          onTap: (r) => context.push('/employee/leave-requests/${r.id}'),
        ),
      ),
    );
  }
}
