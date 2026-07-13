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
import 'package:algo_erp_front/features/accounts_account_group/account_group_di.dart';
import 'package:algo_erp_front/features/accounts_account_group/account_group_manifest.dart';
import 'package:algo_erp_front/features/accounts_account_group/bloc/account_group_list_bloc.dart';
import 'package:algo_erp_front/features/accounts_account_group/bloc/account_group_list_event.dart';
import 'package:algo_erp_front/features/accounts_account_group/bloc/account_group_list_state.dart';
import 'package:algo_erp_front/features/accounts_account_group/domain/account_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AccountGroupListPage extends StatelessWidget {
  const AccountGroupListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<AccountGroupListBloc>(
      create: (_) =>
          AccountGroupListBloc(repository: createAccountGroupRepository(dio))
            ..add(const AccountGroupListFetchRequested()),
      child: BlocListener<AccountGroupListBloc, AccountGroupListState>(
        listenWhen: (prev, curr) => prev.actionMessage != curr.actionMessage,
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        child: const _AccountGroupListView(),
      ),
    );
  }
}

class _AccountGroupListView extends StatelessWidget {
  const _AccountGroupListView();

  Future<void> _delete(BuildContext context, AccountGroup item) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${item.name}?',
      message: 'This will permanently remove the account group.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<AccountGroupListBloc>().add(
        AccountGroupItemDeleted(item.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<AccountGroupListBloc, AccountGroupListState>(
        builder: (context, state) {
          final bloc = context.read<AccountGroupListBloc>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      accountGroupManifest.label,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  PermissionGate(
                    module: accountGroupManifest.rbacModule,
                    action: PermissionAction.create,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/accounts/groups/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('New Account Group'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: AppTextField(
                  label: 'Search Account Group',
                  value: state.search,
                  onChanged: (v) => bloc.add(AccountGroupListSearchChanged(v)),
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
    AccountGroupListState state,
    AccountGroupListBloc bloc,
  ) {
    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure:
            state.failure ??
            const Failure.unknown('Failed to load account groups'),
        onRetry: () => bloc.add(const AccountGroupListFetchRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        message: 'No account groups found',
        actionLabel: 'New Account Group',
        onAction: () => context.push('/accounts/groups/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const AccountGroupListRefreshed()),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = state.items[i];
          return ListTile(
            title: Text(item.fullPath ?? item.name),
            subtitle: Text(
              [
                if (item.code != null && item.code!.isNotEmpty)
                  'Code: ${item.code}',
                if (item.isSystemDefined) 'System Defined',
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/accounts/groups/${item.id}'),
                ),
                if (!item.isSystemDefined)
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, item),
                  ),
              ],
            ),
            onTap: () => context.push('/accounts/groups/${item.id}'),
          );
        },
      ),
    );
  }
}
