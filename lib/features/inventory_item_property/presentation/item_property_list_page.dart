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
import 'package:algo_erp_front/features/inventory_item_property/bloc/item_property_list_bloc.dart';
import 'package:algo_erp_front/features/inventory_item_property/bloc/item_property_list_event.dart';
import 'package:algo_erp_front/features/inventory_item_property/bloc/item_property_list_state.dart';
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
    final dio = getIt<DioClient>();
    return BlocProvider<ItemPropertyListBloc>(
      create: (_) =>
          ItemPropertyListBloc(repository: createItemPropertyRepository(dio))
            ..add(const ItemPropertyListFetchRequested()),
      child: BlocListener<ItemPropertyListBloc, ItemPropertyListState>(
        listenWhen: (prev, curr) => prev.actionMessage != curr.actionMessage,
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        child: const _ItemPropertyListView(),
      ),
    );
  }
}

class _ItemPropertyListView extends StatelessWidget {
  const _ItemPropertyListView();

  Future<void> _delete(BuildContext context, ItemProperty item) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Property for ${item.itemId}?',
      message: 'This will permanently remove the item property.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<ItemPropertyListBloc>().add(
        ItemPropertyItemDeleted(item.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<ItemPropertyListBloc, ItemPropertyListState>(
        builder: (context, state) {
          final bloc = context.read<ItemPropertyListBloc>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      itemPropertyManifest.label,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  PermissionGate(
                    module: itemPropertyManifest.rbacModule,
                    action: PermissionAction.create,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/inventory/property/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('New Property'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: AppTextField(
                  label: 'Search Item ID',
                  value: state.search,
                  onChanged: (v) => bloc.add(ItemPropertyListSearchChanged(v)),
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
    ItemPropertyListState state,
    ItemPropertyListBloc bloc,
  ) {
    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure:
            state.failure ?? const Failure.unknown('Failed to load properties'),
        onRetry: () => bloc.add(const ItemPropertyListFetchRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        message: 'No properties found',
        actionLabel: 'New Property',
        onAction: () => context.push('/inventory/property/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const ItemPropertyListRefreshed()),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = state.items[i];

          return ListTile(
            title: Text('Item ID: ${item.itemId}'),
            subtitle: Text('Default Value: ${item.defaultValue ?? '—'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'View',
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () =>
                      context.push('/inventory/property/${item.id}'),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, item),
                ),
              ],
            ),
            onTap: () => context.push('/inventory/property/${item.id}'),
          );
        },
      ),
    );
  }
}
