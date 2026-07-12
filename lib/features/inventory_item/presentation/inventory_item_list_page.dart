import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class InventoryItemListPage extends StatelessWidget {
  const InventoryItemListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See inventoryItemCrudBloc.
    return BlocProvider<CrudBloc<InventoryItem, int, void>>.value(
      value: inventoryItemCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<InventoryItem>(
          manifest: inventoryItemManifest,
          idOf: (i) => i.id,
          onCreate: () => context.push('/inventory/item/new'),
          onTap: (i) => context.push('/inventory/item/${i.id}'),
        ),
      ),
    );
  }
}
