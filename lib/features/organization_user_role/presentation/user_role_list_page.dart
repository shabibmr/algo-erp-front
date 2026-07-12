import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/organization_user_role/domain/user_role.dart';
import 'package:algo_erp_front/features/organization_user_role/user_role_di.dart';
import 'package:algo_erp_front/features/organization_user_role/user_role_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UserRoleListPage extends StatelessWidget {
  const UserRoleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See userRoleCrudBloc.
    return BlocProvider<CrudBloc<UserRole, int, void>>.value(
      value: userRoleCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<UserRole>(
          manifest: userRoleManifest,
          idOf: (role) => role.id,
          onCreate: () => context.push('/organization/roles/new'),
          onTap: (role) => context.push('/organization/roles/${role.id}'),
        ),
      ),
    );
  }
}
