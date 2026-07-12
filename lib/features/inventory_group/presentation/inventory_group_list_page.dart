import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:algo_erp_front/features/inventory_group/inventory_group_di.dart';
import 'package:algo_erp_front/features/inventory_group/inventory_group_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class InventoryGroupListPage extends StatelessWidget {
  const InventoryGroupListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See inventoryGroupCrudBloc.
    return BlocProvider<CrudBloc<InventoryGroup, int, void>>.value(
      value: inventoryGroupCrudBloc(context),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inventoryGroupManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<InventoryGroup>(
                manifest: inventoryGroupManifest,
                idOf: (g) => g.id,
                onCreate: () => context.push('/inventory/group/new'),
                onTap: (g) => context.push('/inventory/group/${g.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
