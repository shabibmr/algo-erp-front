import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
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
    return BlocProvider<CrudBloc<InventoryItem, int, void>>(
      create: (_) => createInventoryItemCrudBloc(getIt<DioClient>())
        ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inventoryItemManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<InventoryItem>(
                manifest: inventoryItemManifest,
                idOf: (i) => i.id,
                onCreate: () => context.push('/inventory/item/new'),
                onTap: (i) => context.push('/inventory/item/${i.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
