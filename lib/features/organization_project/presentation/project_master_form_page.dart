import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/organization_project/domain/project_master.dart';
import 'package:algo_erp_front/features/organization_project/project_master_di.dart';
import 'package:algo_erp_front/features/organization_project/project_master_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProjectMasterFormPage extends StatelessWidget {
  const ProjectMasterFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<ProjectMaster, int>>(
      create: (_) => createProjectMasterRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          void refreshListAndReturn() {
            projectMasterCrudBloc(context).add(const CrudRefreshRequested());
            context.go(projectMasterManifest.resourcePath);
          }

          final surface = MasterFormSurface<ProjectMaster, int>(
            manifest: projectMasterManifest,
            mode: mode,
            idOf: (p) => p.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(projectMasterManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: mode == FormMode.edit
                ? BlocProvider<DetailBloc<ProjectMaster, int>>(
                    create: (ctx) => DetailBloc<ProjectMaster, int>(
                      repository: ctx.read<Repository<ProjectMaster, int>>(),
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
