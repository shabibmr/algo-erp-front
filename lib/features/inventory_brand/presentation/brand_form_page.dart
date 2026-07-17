import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_di.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_manifest.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Brand's create/edit screen — EMR path via [MasterFormSurface].
class BrandFormPage extends StatelessWidget {
  const BrandFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<Brand, int>>(
      create: (_) => createBrandRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          // The surface has already persisted through the repository by the
          // time these fire, so the shared list bloc is told to refetch —
          // never CrudItemCreated/Updated/Deleted, which would write again.
          void refreshListAndReturn() {
            brandCrudBloc(context).add(const CrudRefreshRequested());
            context.go(brandManifest.resourcePath);
          }

          final surface = MasterFormSurface<Brand, int>(
            manifest: brandManifest,
            mode: mode,
            idOf: (b) => b.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(brandManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: mode == FormMode.edit
                ? BlocProvider<DetailBloc<Brand, int>>(
                    create: (ctx) => DetailBloc<Brand, int>(
                      repository: ctx.read<Repository<Brand, int>>(),
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
