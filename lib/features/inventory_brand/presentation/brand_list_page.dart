import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_di.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_manifest.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Brand's list screen — EMR path via shared [brandCrudBloc].
class BrandListPage extends StatelessWidget {
  const BrandListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See brandCrudBloc.
    return BlocProvider<CrudBloc<Brand, int, void>>.value(
      value: brandCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<Brand>(
          manifest: brandManifest,
          idOf: (b) => b.id,
          onCreate: () => context.push('/inventory/brand/new'),
          onTap: (b) => context.push('/inventory/brand/${b.id}'),
        ),
      ),
    );
  }
}
