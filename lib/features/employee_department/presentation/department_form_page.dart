import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/employee_department/department_di.dart';
import 'package:algo_erp_front/features/employee_department/department_manifest.dart';
import 'package:algo_erp_front/features/employee_department/domain/department.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Department's create/edit screen — same shape as `BrandFormPage`.
class DepartmentFormPage extends StatelessWidget {
  const DepartmentFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<Department, int>>(
      create: (_) => createDepartmentRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          final surface = MasterFormSurface<Department, int>(
            manifest: departmentManifest,
            mode: mode,
            idOf: (d) => d.id,
            onSaved: (_) => context.go(departmentManifest.resourcePath),
            onDeleted: () => context.go(departmentManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${departmentManifest.label}'
                      : departmentManifest.supportsUpdate
                          ? 'Edit ${departmentManifest.label}'
                          : 'View ${departmentManifest.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (mode == FormMode.edit)
                  BlocProvider<DetailBloc<Department, int>>(
                    create: (ctx) => DetailBloc<Department, int>(
                      repository: ctx.read<Repository<Department, int>>(),
                      id: entityId!,
                    )..add(const DetailLoadRequested()),
                    child: surface,
                  )
                else
                  surface,
              ],
            ),
          );
        },
      ),
    );
  }
}
