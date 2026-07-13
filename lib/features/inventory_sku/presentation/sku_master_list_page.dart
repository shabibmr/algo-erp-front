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
import 'package:algo_erp_front/features/inventory_sku/bloc/sku_master_list_bloc.dart';
import 'package:algo_erp_front/features/inventory_sku/bloc/sku_master_list_event.dart';
import 'package:algo_erp_front/features/inventory_sku/bloc/sku_master_list_state.dart';
import 'package:algo_erp_front/features/inventory_sku/domain/sku_master.dart';
import 'package:algo_erp_front/features/inventory_sku/sku_master_di.dart';
import 'package:algo_erp_front/features/inventory_sku/sku_master_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SkuMasterListPage extends StatelessWidget {
  const SkuMasterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<SkuMasterListBloc>(
      create: (_) =>
          SkuMasterListBloc(repository: createSkuMasterRepository(dio))
            ..add(const SkuMasterListFetchRequested()),
      child: BlocListener<SkuMasterListBloc, SkuMasterListState>(
        listenWhen: (prev, curr) => prev.actionMessage != curr.actionMessage,
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        child: const _SkuMasterListView(),
      ),
    );
  }
}

class _SkuMasterListView extends StatelessWidget {
  const _SkuMasterListView();

  Future<void> _delete(BuildContext context, SkuMaster item) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${item.name ?? 'SKU'}?',
      message: 'This will permanently remove the SKU.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<SkuMasterListBloc>().add(SkuMasterItemDeleted(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<SkuMasterListBloc, SkuMasterListState>(
        builder: (context, state) {
          final bloc = context.read<SkuMasterListBloc>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      skuMasterManifest.label,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  PermissionGate(
                    module: skuMasterManifest.rbacModule,
                    action: PermissionAction.create,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/inventory/sku/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('New SKU'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: AppTextField(
                  label: 'Search SKU',
                  value: state.search,
                  onChanged: (v) => bloc.add(SkuMasterListSearchChanged(v)),
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
    SkuMasterListState state,
    SkuMasterListBloc bloc,
  ) {
    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure: state.failure ?? const Failure.unknown('Failed to load SKUs'),
        onRetry: () => bloc.add(const SkuMasterListFetchRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        message: 'No SKUs found',
        actionLabel: 'New SKU',
        onAction: () => context.push('/inventory/sku/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const SkuMasterListRefreshed()),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = state.items[i];

          return ListTile(
            title: Text(item.name ?? 'Unnamed SKU'),
            subtitle: Text(
              [
                if (item.code != null && item.code!.isNotEmpty)
                  'Code: ${item.code}',
                if (item.barcode != null && item.barcode!.isNotEmpty)
                  'Barcode: ${item.barcode}',
                if (item.rate != null) 'Rate: ${item.rate}',
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/inventory/sku/${item.id}'),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, item),
                ),
              ],
            ),
            onTap: () => context.push('/inventory/sku/${item.id}'),
          );
        },
      ),
    );
  }
}
