import 'package:algo_erp_front/core/bloc/crud_contract.dart';
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
          // The surface has already persisted through the repository by the
          // time these fire, so the shared list bloc is told to refetch —
          // never CrudItemCreated/Updated/Deleted, which would write again.
          void refreshListAndReturn() {
            designationCrudBloc(context).add(const CrudRefreshRequested());
            context.go(designationManifest.resourcePath);
          }

          final surface = MasterFormSurface<Designation, int>(
            manifest: designationManifest,
            mode: mode,
            idOf: (d) => d.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(designationManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: mode == FormMode.edit
                ? BlocProvider<DetailBloc<Designation, int>>(
                    create: (ctx) => DetailBloc<Designation, int>(
                      repository: ctx.read<Repository<Designation, int>>(),
                      id: entityId!,
                    )..add(const DetailLoadRequested()),
                    child: surface,
                  )
                : surface,
          );
        },
      ),
    );
  }
}
