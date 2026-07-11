import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_di.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_manifest.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Brand's list screen — the EMR vertical slice's one real page. Thin by
/// design: it only provides the `CrudBloc` and hands the manifest to
/// `MasterListSurface`; there is no Brand-specific list/table code here.
class BrandListPage extends StatelessWidget {
  const BrandListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<Brand, int, void>>(
      create: (_) => createBrandCrudBloc(getIt<DioClient>())
        ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              brandManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<Brand>(
                manifest: brandManifest,
                idOf: (brand) => brand.id,
                // Detail/form Surfaces are out of this slice's scope — tap
                // and create are no-ops until they exist.
              ),
            ),
          ],
        ),
      ),
    );
  }
}
