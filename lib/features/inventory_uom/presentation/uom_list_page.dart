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
import 'package:algo_erp_front/features/inventory_uom/bloc/uom_list_bloc.dart';
import 'package:algo_erp_front/features/inventory_uom/bloc/uom_list_event.dart';
import 'package:algo_erp_front/features/inventory_uom/bloc/uom_list_state.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';
import 'package:algo_erp_front/features/inventory_uom/uom_di.dart';
import 'package:algo_erp_front/features/inventory_uom/uom_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UomListPage extends StatelessWidget {
  const UomListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<UomListBloc>(
      create: (_) =>
          UomListBloc(repository: createUomRepository(dio))
            ..add(const UomListFetchRequested()),
      child: BlocListener<UomListBloc, UomListState>(
        listenWhen: (prev, curr) => prev.actionMessage != curr.actionMessage,
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        child: const _UomListView(),
      ),
    );
  }
}

class _UomListView extends StatelessWidget {
  const _UomListView();

  Future<void> _delete(BuildContext context, Uom item) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${item.name}?',
      message: 'This will permanently remove the unit of measure.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<UomListBloc>().add(UomItemDeleted(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<UomListBloc, UomListState>(
        builder: (context, state) {
          final bloc = context.read<UomListBloc>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      uomManifest.label,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  PermissionGate(
                    module: uomManifest.rbacModule,
                    action: PermissionAction.create,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/inventory/uom/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('New UOM'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: AppTextField(
                  label: 'Search UOM',
                  value: state.search,
                  onChanged: (v) => bloc.add(UomListSearchChanged(v)),
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
    UomListState state,
    UomListBloc bloc,
  ) {
    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure: state.failure ?? const Failure.unknown('Failed to load UOMs'),
        onRetry: () => bloc.add(const UomListFetchRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        message: 'No units of measure found',
        actionLabel: 'New UOM',
        onAction: () => context.push('/inventory/uom/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const UomListRefreshed()),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = state.items[i];
          return ListTile(
            title: Text(item.name),
            subtitle: Text(
              [
                if (item.code != null && item.code!.isNotEmpty)
                  'Code: ${item.code}',
                if (item.symbol != null && item.symbol!.isNotEmpty)
                  'Symbol: ${item.symbol}',
                'Decimals: ${item.decimalPlaces}',
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/inventory/uom/${item.id}'),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, item),
                ),
              ],
            ),
            onTap: () => context.push('/inventory/uom/${item.id}'),
          );
        },
      ),
    );
  }
}
