import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/inventory_category/category_di.dart';
import 'package:algo_erp_front/features/inventory_category/category_manifest.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Category's create/edit screen — EMR path via [MasterFormSurface].
class CategoryFormPage extends StatelessWidget {
  const CategoryFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<Category, int>>(
      create: (_) => createCategoryRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          // The surface has already persisted through the repository by the
          // time these fire, so the shared list bloc is told to refetch —
          // never CrudItemCreated/Updated/Deleted, which would write again.
          void refreshListAndReturn() {
            categoryCrudBloc(context).add(const CrudRefreshRequested());
            context.go(categoryManifest.resourcePath);
          }

          final surface = MasterFormSurface<Category, int>(
            manifest: categoryManifest,
            mode: mode,
            idOf: (c) => c.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(categoryManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: mode == FormMode.edit
                ? BlocProvider<DetailBloc<Category, int>>(
                    create: (ctx) => DetailBloc<Category, int>(
                      repository: ctx.read<Repository<Category, int>>(),
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
