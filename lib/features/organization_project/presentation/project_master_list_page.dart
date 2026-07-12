import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/organization_project/domain/project_master.dart';
import 'package:algo_erp_front/features/organization_project/project_master_di.dart';
import 'package:algo_erp_front/features/organization_project/project_master_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProjectMasterListPage extends StatelessWidget {
  const ProjectMasterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<ProjectMaster, int, void>>.value(
      value: projectMasterCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<ProjectMaster>(
          manifest: projectMasterManifest,
          idOf: (p) => p.id,
          onCreate: () => context.push('/organization/projects/new'),
          onTap: (p) => context.push('/organization/projects/${p.id}'),
        ),
      ),
    );
  }
}
