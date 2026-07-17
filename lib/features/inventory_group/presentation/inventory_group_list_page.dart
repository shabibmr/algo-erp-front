import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/export/export_button.dart';
import 'package:algo_erp_front/core/export/export_cubit.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/shortcuts/create_new_shortcuts.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/inventory_group/bloc/inventory_group_list_bloc.dart';
import 'package:algo_erp_front/features/inventory_group/bloc/inventory_group_list_event.dart';
import 'package:algo_erp_front/features/inventory_group/bloc/inventory_group_list_state.dart';
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
    // One repository, two blocs: the list reads pages through it, and export
    // walks every page of the same query through it.
    final repository = createInventoryGroupRepository(getIt<DioClient>());
    return MultiBlocProvider(
      providers: [
        BlocProvider<InventoryGroupListBloc>(
          create: (_) =>
              InventoryGroupListBloc(repository: repository)
                ..add(const InventoryGroupListFetchRequested()),
        ),
        BlocProvider<ExportCubit<InventoryGroup>>(
          create: (_) => ExportCubit<InventoryGroup>(source: repository.list),
        ),
      ],
      child: BlocListener<InventoryGroupListBloc, InventoryGroupListState>(
        listenWhen: (prev, curr) => prev.actionMessage != curr.actionMessage,
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        child: const _InventoryGroupListView(),
      ),
    );
  }
}

class _InventoryGroupListView extends StatelessWidget {
  const _InventoryGroupListView();

  Future<void> _delete(BuildContext context, InventoryGroup item) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${item.name}?',
      message: 'This will permanently remove the inventory group.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<InventoryGroupListBloc>().add(
        InventoryGroupItemDeleted(item.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<InventoryGroupListBloc, InventoryGroupListState>(
        builder: (context, state) {
          final bloc = context.read<InventoryGroupListBloc>();

          return CreateNewShortcuts(
            module: inventoryGroupManifest.rbacModule,
            onCreate: () => context.push('/inventory/group/new'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        inventoryGroupManifest.label,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    if (inventoryGroupManifest.supportsExport)
                      ExportButton<InventoryGroup>.fromManifest(
                        manifest: inventoryGroupManifest,
                        query: () => state.query,
                      ),
                    PermissionGate(
                      module: inventoryGroupManifest.rbacModule,
                      action: PermissionAction.create,
                      child: FilledButton.icon(
                        onPressed: () => context.push('/inventory/group/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('New Group'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 300,
                  child: AppTextField(
                    label: 'Search Group',
                    value: state.search,
                    onChanged: (v) =>
                        bloc.add(InventoryGroupListSearchChanged(v)),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildListContent(context, state, bloc)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    InventoryGroupListState state,
    InventoryGroupListBloc bloc,
  ) {
    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure:
            state.failure ?? const Failure.unknown('Failed to load groups'),
        onRetry: () => bloc.add(const InventoryGroupListFetchRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        message: 'No groups found',
        actionLabel: 'New Group',
        onAction: () => context.push('/inventory/group/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const InventoryGroupListRefreshed()),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = state.items[i];
          final depth = item.depth ?? 0;
          final indent = depth > 0 ? '${'  ' * depth}↳ ' : '';

          return ListTile(
            title: Text('$indent${item.name}'),
            subtitle: Text(
              [
                if (item.code != null && item.code!.isNotEmpty)
                  'Code: ${item.code}',
                if (item.groupType != null && item.groupType!.isNotEmpty)
                  'Type: ${item.groupType}',
                if (item.fullPath != null && item.fullPath!.isNotEmpty)
                  'Path: ${item.fullPath}',
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/inventory/group/${item.id}'),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, item),
                ),
              ],
            ),
            onTap: () => context.push('/inventory/group/${item.id}'),
          );
        },
      ),
    );
  }
}
