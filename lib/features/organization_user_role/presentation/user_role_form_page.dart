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
          final surface = MasterFormSurface<UserRole, int>(
            manifest: userRoleManifest,
            mode: mode,
            idOf: (role) => role.id,
            onSaved: (_) => context.go(userRoleManifest.resourcePath),
            onDeleted: () => context.go(userRoleManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${userRoleManifest.label}'
                      : 'Edit ${userRoleManifest.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (mode == FormMode.edit)
                  BlocProvider<DetailBloc<UserRole, int>>(
                    create: (ctx) => DetailBloc<UserRole, int>(
                      repository: ctx.read<Repository<UserRole, int>>(),
                      id: entityId!,
                    )..add(const DetailLoadRequested()),
                    child: surface,
                  )
                else
                  surface,
              ],
            ),
          );
        },
      ),
    );
  }
}
