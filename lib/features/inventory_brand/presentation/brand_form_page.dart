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

/// Brand's create/edit screen — thin by design, mirroring `BrandListPage`:
/// it only provides the repository (and, in edit mode, a `DetailBloc`) and
/// hands the manifest to `MasterFormSurface`.
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
          final surface = MasterFormSurface<Brand, int>(
            manifest: brandManifest,
            mode: mode,
            idOf: (brand) => brand.id,
            onSaved: (_) => context.go(brandManifest.resourcePath),
            onDeleted: () => context.go(brandManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${brandManifest.label}'
                      : brandManifest.supportsUpdate
                          ? 'Edit ${brandManifest.label}'
                          : 'View ${brandManifest.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (mode == FormMode.edit)
                  BlocProvider<DetailBloc<Brand, int>>(
                    create: (ctx) => DetailBloc<Brand, int>(
                      repository: ctx.read<Repository<Brand, int>>(),
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
