import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/organization_user_role/bloc/role_permissions_bloc.dart';
import 'package:algo_erp_front/features/organization_user_role/bloc/role_permissions_event.dart';
import 'package:algo_erp_front/features/organization_user_role/bloc/role_permissions_state.dart';
import 'package:algo_erp_front/features/organization_user_role/data/role_permissions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Editable RBAC matrix for one role (full replace on save) powered by flutter_bloc.
class RolePermissionsPage extends StatelessWidget {
  const RolePermissionsPage({required this.roleId, this.roleName, super.key});

  final int roleId;
  final String? roleName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RolePermissionsBloc>(
      create: (_) => RolePermissionsBloc(
        repository: RolePermissionsRepository(getIt<DioClient>()),
      )..add(RolePermissionsFetchRequested(roleId)),
      child: BlocListener<RolePermissionsBloc, RolePermissionsState>(
        listenWhen: (prev, curr) => prev.saveSuccess != curr.saveSuccess,
        listener: (context, state) {
          if (state.saveSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Permissions saved')));
          }
        },
        child: _RolePermissionsView(roleId: roleId, roleName: roleName),
      ),
    );
  }
}

class _RolePermissionsView extends StatelessWidget {
  const _RolePermissionsView({required this.roleId, this.roleName});

  final int roleId;
  final String? roleName;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final title = roleName == null ? 'Permissions' : 'Permissions · $roleName';

    return AdaptiveLayout(
      child: BlocBuilder<RolePermissionsBloc, RolePermissionsState>(
        builder: (context, state) {
          final bloc = context.read<RolePermissionsBloc>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.go('/organization/roles/$roleId'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  FilledButton(
                    onPressed: state.isSaving
                        ? null
                        : () => bloc.add(const RolePermissionsSaved()),
                    child: state.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save matrix'),
                  ),
                ],
              ),
              SizedBox(height: tokens.spacing.sm),
              Text(
                'Saving replaces the role’s full permission matrix. '
                'Modules with no checks are removed.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (state.errorMessage != null) ...[
                SizedBox(height: tokens.spacing.sm),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: tokens.semanticColors.danger),
                ),
              ],
              SizedBox(height: tokens.spacing.md),
              Expanded(child: _buildBody(context, state, bloc)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RolePermissionsState state,
    RolePermissionsBloc bloc,
  ) {
    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure:
            state.failure ?? const Failure.unknown('Failed to load matrix'),
        onRetry: () => bloc.add(RolePermissionsFetchRequested(roleId)),
      );
    }

    const modules = kPermissionMatrixModules;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 720,
        child: ListView.separated(
          itemCount: modules.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            if (i == 0) {
              return ListTile(
                title: Text(
                  'Module',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                trailing: const SizedBox(
                  width: 280,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('C'),
                      Text('R'),
                      Text('U'),
                      Text('D'),
                      Text('S'),
                    ],
                  ),
                ),
              );
            }
            final module = modules[i - 1];
            final row = state.rows[module] ?? ModulePermissions(module: module);

            Widget box({
              required bool value,
              required PermissionAction action,
            }) => Checkbox(
              value: value,
              onChanged: state.isSaving
                  ? null
                  : (v) => bloc.add(
                      RolePermissionToggled(
                        module: module,
                        action: action,
                        value: v ?? false,
                      ),
                    ),
            );

            return ListTile(
              title: Text(module),
              trailing: SizedBox(
                width: 280,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    box(value: row.create, action: PermissionAction.create),
                    box(value: row.read, action: PermissionAction.read),
                    box(value: row.update, action: PermissionAction.update),
                    box(value: row.delete, action: PermissionAction.delete),
                    box(value: row.share, action: PermissionAction.share),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
