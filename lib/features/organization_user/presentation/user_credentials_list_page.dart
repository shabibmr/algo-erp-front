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
import 'package:algo_erp_front/features/organization_user/bloc/user_credentials_list_bloc.dart';
import 'package:algo_erp_front/features/organization_user/bloc/user_credentials_list_event.dart';
import 'package:algo_erp_front/features/organization_user/bloc/user_credentials_list_state.dart';
import 'package:algo_erp_front/features/organization_user/domain/user_credentials.dart';
import 'package:algo_erp_front/features/organization_user/user_credentials_di.dart';
import 'package:algo_erp_front/features/organization_user/user_credentials_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UserCredentialsListPage extends StatelessWidget {
  const UserCredentialsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // One repository, two blocs: the list reads pages through it, and export
    // walks every page of the same query through it.
    final repository = createUserCredentialsRepository(getIt<DioClient>());
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserCredentialsListBloc>(
          create: (_) =>
              UserCredentialsListBloc(repository: repository)
                ..add(const UserCredentialsListFetchRequested()),
        ),
        BlocProvider<ExportCubit<UserCredentials>>(
          create: (_) => ExportCubit<UserCredentials>(source: repository.list),
        ),
      ],
      child: BlocListener<UserCredentialsListBloc, UserCredentialsListState>(
        listenWhen: (prev, curr) => prev.actionMessage != curr.actionMessage,
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        child: const _UserCredentialsListView(),
      ),
    );
  }
}

class _UserCredentialsListView extends StatelessWidget {
  const _UserCredentialsListView();

  Future<void> _delete(BuildContext context, UserCredentials item) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Deactivate ${item.username}?',
      message: 'This will temporarily deactivate the user account.',
      confirmLabel: 'Deactivate',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<UserCredentialsListBloc>().add(
        UserCredentialsItemDeleted(item.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<UserCredentialsListBloc, UserCredentialsListState>(
        builder: (context, state) {
          final bloc = context.read<UserCredentialsListBloc>();

          return CreateNewShortcuts(
            module: userCredentialsManifest.rbacModule,
            onCreate: () => context.push('/organization/users/new'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userCredentialsManifest.label,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    if (userCredentialsManifest.supportsExport)
                      ExportButton<UserCredentials>.fromManifest(
                        manifest: userCredentialsManifest,
                        query: () => state.query,
                      ),
                    PermissionGate(
                      module: userCredentialsManifest.rbacModule,
                      action: PermissionAction.create,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.push('/organization/users/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('New User'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 300,
                  child: AppTextField(
                    label: 'Search User',
                    value: state.search,
                    onChanged: (v) =>
                        bloc.add(UserCredentialsListSearchChanged(v)),
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
    UserCredentialsListState state,
    UserCredentialsListBloc bloc,
  ) {
    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure: state.failure ?? const Failure.unknown('Failed to load users'),
        onRetry: () => bloc.add(const UserCredentialsListFetchRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        message: 'No users found',
        actionLabel: 'New User',
        onAction: () => context.push('/organization/users/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const UserCredentialsListRefreshed()),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = state.items[i];
          return ListTile(
            title: Text(item.username),
            subtitle: Text(
              [
                'Role ID: ${item.roleId}',
                item.isActive ? 'Active' : 'Inactive',
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      context.push('/organization/users/${item.id}'),
                ),
                IconButton(
                  tooltip: 'Deactivate',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, item),
                ),
              ],
            ),
            onTap: () => context.push('/organization/users/${item.id}'),
          );
        },
      ),
    );
  }
}
