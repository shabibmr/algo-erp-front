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
import 'package:algo_erp_front/features/inventory_godown/bloc/godown_list_bloc.dart';
import 'package:algo_erp_front/features/inventory_godown/bloc/godown_list_event.dart';
import 'package:algo_erp_front/features/inventory_godown/bloc/godown_list_state.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_di.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GodownListPage extends StatelessWidget {
  const GodownListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<GodownListBloc>(
      create: (_) =>
          GodownListBloc(repository: createGodownRepository(dio))
            ..add(const GodownListFetchRequested()),
      child: BlocListener<GodownListBloc, GodownListState>(
        listenWhen: (prev, curr) => prev.actionMessage != curr.actionMessage,
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        child: const _GodownListView(),
      ),
    );
  }
}

class _GodownListView extends StatelessWidget {
  const _GodownListView();

  Future<void> _delete(BuildContext context, Godown item) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${item.name}?',
      message: 'This will permanently remove the godown/warehouse.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<GodownListBloc>().add(GodownItemDeleted(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<GodownListBloc, GodownListState>(
        builder: (context, state) {
          final bloc = context.read<GodownListBloc>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      godownManifest.label,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  PermissionGate(
                    module: godownManifest.rbacModule,
                    action: PermissionAction.create,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/inventory/godown/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('New Godown'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: AppTextField(
                  label: 'Search Godown',
                  value: state.search,
                  onChanged: (v) => bloc.add(GodownListSearchChanged(v)),
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
    GodownListState state,
    GodownListBloc bloc,
  ) {
    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure:
            state.failure ?? const Failure.unknown('Failed to load godowns'),
        onRetry: () => bloc.add(const GodownListFetchRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        message: 'No godowns found',
        actionLabel: 'New Godown',
        onAction: () => context.push('/inventory/godown/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const GodownListRefreshed()),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = state.items[i];
          final flags = [
            if (item.isDefault) 'Default',
            if (item.isProfitCentre) 'Profit Centre',
            if (item.isProduction) 'Production',
          ];

          return ListTile(
            title: Text(item.name),
            subtitle: Text(
              [
                if (item.code != null && item.code!.isNotEmpty)
                  'Code: ${item.code}',
                if (item.location != null && item.location!.isNotEmpty)
                  'Location: ${item.location}',
                if (flags.isNotEmpty) flags.join(', '),
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/inventory/godown/${item.id}'),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, item),
                ),
              ],
            ),
            onTap: () => context.push('/inventory/godown/${item.id}'),
          );
        },
      ),
    );
  }
}
