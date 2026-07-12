import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/employee_department/department_di.dart';
import 'package:algo_erp_front/features/employee_department/department_manifest.dart';
import 'package:algo_erp_front/features/employee_department/domain/department.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Department's list screen — same shape as `BrandListPage`.
class DepartmentListPage extends StatelessWidget {
  const DepartmentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See departmentCrudBloc.
    return BlocProvider<CrudBloc<Department, int, void>>.value(
      value: departmentCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<Department>(
          manifest: departmentManifest,
          idOf: (d) => d.id,
          onCreate: () => context.push('/employee/department/new'),
          onTap: (d) => context.push('/employee/department/${d.id}'),
        ),
      ),
    );
  }
}
