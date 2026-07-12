import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:algo_erp_front/features/employee_employee/employee_di.dart';
import 'package:algo_erp_front/features/employee_employee/employee_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class EmployeeListPage extends StatelessWidget {
  const EmployeeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<Employee, int, void>>.value(
      value: employeeCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<Employee>(
          manifest: employeeManifest,
          idOf: (e) => e.id,
          onCreate: () => context.push('/employee/employees/new'),
          onTap: (e) => context.push('/employee/employees/${e.id}'),
        ),
      ),
    );
  }
}
