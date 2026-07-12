import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/employee_leave_policy/domain/leave_policy.dart';
import 'package:algo_erp_front/features/employee_leave_policy/leave_policy_di.dart';
import 'package:algo_erp_front/features/employee_leave_policy/leave_policy_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LeavePolicyListPage extends StatelessWidget {
  const LeavePolicyListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<LeavePolicy, int, void>>.value(
      value: leavePolicyCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<LeavePolicy>(
          manifest: leavePolicyManifest,
          idOf: (p) => p.id,
          onCreate: () => context.push('/employee/leave/policies/new'),
          onTap: (p) => context.push('/employee/leave/policies/${p.id}'),
        ),
      ),
    );
  }
}
