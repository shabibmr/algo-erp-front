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
import 'package:algo_erp_front/features/accounts_ledger/bloc/ledger_list_bloc.dart';
import 'package:algo_erp_front/features/accounts_ledger/bloc/ledger_list_event.dart';
import 'package:algo_erp_front/features/accounts_ledger/bloc/ledger_list_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LedgerListPage extends StatelessWidget {
  const LedgerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<LedgerListBloc>(
      create: (_) =>
          LedgerListBloc(repository: createLedgerRepository(dio))
            ..add(const LedgerListFetchRequested()),
      child: BlocListener<LedgerListBloc, LedgerListState>(
        listenWhen: (prev, curr) => prev.actionMessage != curr.actionMessage,
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        child: const _LedgerListView(),
      ),
    );
  }
}

class _LedgerListView extends StatelessWidget {
  const _LedgerListView();

  Future<void> _delete(BuildContext context, Ledger item) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${item.name}?',
      message: 'This will deactivate the ledger account.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<LedgerListBloc>().add(LedgerItemDeleted(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<LedgerListBloc, LedgerListState>(
        builder: (context, state) {
          final bloc = context.read<LedgerListBloc>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ledgerManifest.label,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  PermissionGate(
                    module: ledgerManifest.rbacModule,
                    action: PermissionAction.create,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/accounts/ledgers/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('New Ledger'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: AppTextField(
                  label: 'Search Ledger',
                  value: state.search,
                  onChanged: (v) => bloc.add(LedgerListSearchChanged(v)),
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
    LedgerListState state,
    LedgerListBloc bloc,
  ) {
    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure:
            state.failure ?? const Failure.unknown('Failed to load ledgers'),
        onRetry: () => bloc.add(const LedgerListFetchRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        message: 'No ledgers found',
        actionLabel: 'New Ledger',
        onAction: () => context.push('/accounts/ledgers/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const LedgerListRefreshed()),
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
                'Type: ${item.ledgerType}',
                'Opening: ${item.currencyCode} ${item.openingBalance}',
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/accounts/ledgers/${item.id}'),
                ),
                if (!item.isSystemDefined)
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, item),
                  ),
              ],
            ),
            onTap: () => context.push('/accounts/ledgers/${item.id}'),
          );
        },
      ),
    );
  }
}
