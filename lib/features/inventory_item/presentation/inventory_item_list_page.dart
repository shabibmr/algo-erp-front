import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/inventory_item/bloc/inventory_item_list_bloc.dart';
import 'package:algo_erp_front/features/inventory_item/bloc/inventory_item_list_event.dart';
import 'package:algo_erp_front/features/inventory_item/bloc/inventory_item_list_state.dart';
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
    final dio = getIt<DioClient>();
    return BlocProvider<InventoryItemListBloc>(
      create: (_) =>
          InventoryItemListBloc(repository: createInventoryItemRepository(dio))
            ..add(const InventoryItemListFetchRequested()),
      child: BlocListener<InventoryItemListBloc, InventoryItemListState>(
        listenWhen: (prev, curr) => prev.actionMessage != curr.actionMessage,
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        child: const _InventoryItemListView(),
      ),
    );
  }
}

class _InventoryItemListView extends StatelessWidget {
  const _InventoryItemListView();

  Future<void> _delete(BuildContext context, InventoryItem item) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${item.name}?',
      message: 'This will permanently remove the inventory item.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<InventoryItemListBloc>().add(
        InventoryItemItemDeleted(item.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<InventoryItemListBloc, InventoryItemListState>(
        builder: (context, state) {
          final bloc = context.read<InventoryItemListBloc>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      inventoryItemManifest.label,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  PermissionGate(
                    module: inventoryItemManifest.rbacModule,
                    action: PermissionAction.create,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/inventory/item/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('New Item'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: AppTextField(
                  label: 'Search Item',
                  value: state.search,
                  onChanged: (v) => bloc.add(InventoryItemListSearchChanged(v)),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildListContent(context, state, bloc)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    InventoryItemListState state,
    InventoryItemListBloc bloc,
  ) {
    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure: state.failure ?? const Failure.unknown('Failed to load items'),
        onRetry: () => bloc.add(const InventoryItemListFetchRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        message: 'No items found',
        actionLabel: 'New Item',
        onAction: () => context.push('/inventory/item/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const InventoryItemListRefreshed()),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = state.items[i];
          final flags = [
            if (item.isSalesItem) 'Sales',
            if (item.isPurchaseItem) 'Purchase',
            if (item.isStockItem) 'Stock',
            if (item.isActive) 'Active' else 'Inactive',
          ];

          return ListTile(
            title: Text(item.name),
            subtitle: Text(
              [
                'Code: ${item.code}',
                'Price: ${item.price}',
                flags.join(', '),
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/inventory/item/${item.id}'),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, item),
                ),
              ],
            ),
            onTap: () => context.push('/inventory/item/${item.id}'),
          );
        },
      ),
    );
  }
}
