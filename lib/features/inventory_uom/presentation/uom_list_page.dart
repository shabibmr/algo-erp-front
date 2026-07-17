import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';
import 'package:algo_erp_front/features/inventory_uom/uom_di.dart';
import 'package:algo_erp_front/features/inventory_uom/uom_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// UOM's list screen — EMR path via shared [uomCrudBloc].
class UomListPage extends StatelessWidget {
  const UomListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See uomCrudBloc.
    return BlocProvider<CrudBloc<Uom, int, void>>.value(
      value: uomCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<Uom>(
          manifest: uomManifest,
          idOf: (u) => u.id,
          onCreate: () => context.push('/inventory/uom/new'),
          onTap: (u) => context.push('/inventory/uom/${u.id}'),
        ),
      ),
    );
  }
}
