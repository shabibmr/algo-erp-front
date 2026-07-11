import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
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
    return BlocProvider<CrudBloc<Department, int, void>>(
      create: (_) => createDepartmentCrudBloc(getIt<DioClient>())
        ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              departmentManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<Department>(
                manifest: departmentManifest,
                idOf: (d) => d.id,
                onCreate: () => context.push('/employee/department/new'),
                onTap: (d) => context.push('/employee/department/${d.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
