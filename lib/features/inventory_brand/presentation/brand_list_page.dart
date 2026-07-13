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
import 'package:algo_erp_front/features/inventory_brand/bloc/brand_list_bloc.dart';
import 'package:algo_erp_front/features/inventory_brand/bloc/brand_list_event.dart';
import 'package:algo_erp_front/features/inventory_brand/bloc/brand_list_state.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_di.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_manifest.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BrandListPage extends StatelessWidget {
  const BrandListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<BrandListBloc>(
      create: (_) =>
          BrandListBloc(repository: createBrandRepository(dio))
            ..add(const BrandListFetchRequested()),
      child: BlocListener<BrandListBloc, BrandListState>(
        listenWhen: (prev, curr) => prev.actionMessage != curr.actionMessage,
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        child: const _BrandListView(),
      ),
    );
  }
}

class _BrandListView extends StatelessWidget {
  const _BrandListView();

  Future<void> _delete(BuildContext context, Brand item) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${item.name}?',
      message: 'This will permanently remove the brand.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<BrandListBloc>().add(BrandItemDeleted(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<BrandListBloc, BrandListState>(
        builder: (context, state) {
          final bloc = context.read<BrandListBloc>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      brandManifest.label,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  PermissionGate(
                    module: brandManifest.rbacModule,
                    action: PermissionAction.create,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/inventory/brand/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('New Brand'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: AppTextField(
                  label: 'Search Brand',
                  value: state.search,
                  onChanged: (v) => bloc.add(BrandListSearchChanged(v)),
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
    BrandListState state,
    BrandListBloc bloc,
  ) {
    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure:
            state.failure ?? const Failure.unknown('Failed to load brands'),
        onRetry: () => bloc.add(const BrandListFetchRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        message: 'No brands found',
        actionLabel: 'New Brand',
        onAction: () => context.push('/inventory/brand/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const BrandListRefreshed()),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = state.items[i];
          return ListTile(
            title: Text(item.name),
            subtitle: Text(
              [
                if (item.description != null && item.description!.isNotEmpty)
                  'Description: ${item.description}',
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/inventory/brand/${item.id}'),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, item),
                ),
              ],
            ),
            onTap: () => context.push('/inventory/brand/${item.id}'),
          );
        },
      ),
    );
  }
}
