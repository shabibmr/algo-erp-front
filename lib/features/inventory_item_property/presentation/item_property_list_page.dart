import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_item_property/domain/item_property.dart';
import 'package:algo_erp_front/features/inventory_item_property/item_property_di.dart';
import 'package:algo_erp_front/features/inventory_item_property/item_property_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ItemPropertyListPage extends StatelessWidget {
  const ItemPropertyListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See itemPropertyCrudBloc.
    return BlocProvider<CrudBloc<ItemProperty, int, void>>.value(
      value: itemPropertyCrudBloc(context),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              itemPropertyManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<ItemProperty>(
                manifest: itemPropertyManifest,
                idOf: (property) => property.id,
                onCreate: () => context.push('/inventory/property/new'),
                onTap: (property) =>
                    context.push('/inventory/property/${property.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
