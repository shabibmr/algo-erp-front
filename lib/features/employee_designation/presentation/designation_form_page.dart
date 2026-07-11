import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/employee_designation/designation_di.dart';
import 'package:algo_erp_front/features/employee_designation/designation_manifest.dart';
import 'package:algo_erp_front/features/employee_designation/domain/designation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Designation's create/edit screen — same shape as `BrandFormPage`. Proves
/// the FK picker end to end: `MasterFormSurface` seeds the Department
/// display value via `fkResolveById` in edit mode and saves the raw
/// `departmentId` on submit.
class DesignationFormPage extends StatelessWidget {
  const DesignationFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<Designation, int>>(
      create: (_) => createDesignationRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          final surface = MasterFormSurface<Designation, int>(
            manifest: designationManifest,
            mode: mode,
            idOf: (d) => d.id,
            onSaved: (_) => context.go(designationManifest.resourcePath),
            onDeleted: () => context.go(designationManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${designationManifest.label}'
                      : 'Edit ${designationManifest.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (mode == FormMode.edit)
                  BlocProvider<DetailBloc<Designation, int>>(
                    create: (ctx) => DetailBloc<Designation, int>(
                      repository: ctx.read<Repository<Designation, int>>(),
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
