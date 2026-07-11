import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
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
    return BlocProvider<CrudBloc<UserRole, int, void>>(
      create: (_) => createUserRoleCrudBloc(getIt<DioClient>())
        ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userRoleManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<UserRole>(
                manifest: userRoleManifest,
                idOf: (role) => role.id,
                onCreate: () => context.push('/organization/roles/new'),
                onTap: (role) =>
                    context.push('/organization/roles/${role.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
