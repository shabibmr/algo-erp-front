import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/inventory_batch/domain/item_batch.dart';
import 'package:algo_erp_front/features/inventory_batch/item_batch_di.dart';
import 'package:algo_erp_front/features/inventory_batch/item_batch_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ItemBatchListPage extends StatelessWidget {
  const ItemBatchListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See itemBatchCrudBloc.
    return BlocProvider<CrudBloc<ItemBatch, int, void>>.value(
      value: itemBatchCrudBloc(context),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              itemBatchManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<ItemBatch>(
                manifest: itemBatchManifest,
                idOf: (b) => b.id,
                onCreate: () => context.push('/inventory/batch/new'),
                onTap: (b) => context.push('/inventory/batch/${b.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
