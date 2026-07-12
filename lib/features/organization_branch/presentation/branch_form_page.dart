import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/organization_branch/branch_di.dart';
import 'package:algo_erp_front/features/organization_branch/branch_manifest.dart';
import 'package:algo_erp_front/features/organization_branch/domain/branch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BranchFormPage extends StatelessWidget {
  const BranchFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<Branch, int>>(
      create: (_) => createBranchRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          // The surface has already persisted through the repository by the
          // time these fire, so the shared list bloc is told to refetch —
          // never CrudItemCreated/Updated/Deleted, which would write again.
          void refreshListAndReturn() {
            branchCrudBloc(context).add(const CrudRefreshRequested());
            context.go(branchManifest.resourcePath);
          }

          final surface = MasterFormSurface<Branch, int>(
            manifest: branchManifest,
            mode: mode,
            idOf: (branch) => branch.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(branchManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: mode == FormMode.edit
                ? BlocProvider<DetailBloc<Branch, int>>(
                    create: (ctx) => DetailBloc<Branch, int>(
                      repository: ctx.read<Repository<Branch, int>>(),
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
