import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/domain/uom_conversion.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/uom_conversion_di.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/uom_conversion_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UomConversionListPage extends StatelessWidget {
  const UomConversionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See uomConversionCrudBloc.
    return BlocProvider<CrudBloc<UomConversion, int, void>>.value(
      value: uomConversionCrudBloc(context),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              uomConversionManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<UomConversion>(
                manifest: uomConversionManifest,
                idOf: (u) => u.id,
                onCreate: () => context.push('/inventory/conversion/new'),
                onTap: (u) => context.push('/inventory/conversion/${u.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
