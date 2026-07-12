import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/organization_user_role/domain/user_role.dart';
import 'package:algo_erp_front/features/organization_user_role/user_role_di.dart';
import 'package:algo_erp_front/features/organization_user_role/user_role_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UserRoleFormPage extends StatelessWidget {
  const UserRoleFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<UserRole, int>>(
      create: (_) => createUserRoleRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          // The surface has already persisted through the repository by the
          // time these fire, so the shared list bloc is told to refetch —
          // never CrudItemCreated/Updated/Deleted, which would write again.
          void refreshListAndReturn() {
            userRoleCrudBloc(context).add(const CrudRefreshRequested());
            context.go(userRoleManifest.resourcePath);
          }

          final surface = MasterFormSurface<UserRole, int>(
            manifest: userRoleManifest,
            mode: mode,
            idOf: (role) => role.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(userRoleManifest.resourcePath),
          );
          final body = mode == FormMode.edit
              ? BlocProvider<DetailBloc<UserRole, int>>(
                  create: (ctx) => DetailBloc<UserRole, int>(
                    repository: ctx.read<Repository<UserRole, int>>(),
                    id: entityId!,
                  )..add(const DetailLoadRequested()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: surface),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/organization/roles/${entityId!}/permissions',
                          ),
                          icon: const Icon(Icons.security),
                          label: const Text('Edit permission matrix'),
                        ),
                      ),
                    ],
                  ),
                )
              : surface;
          return AdaptiveLayout(child: body);
        },
      ),
    );
  }
}
