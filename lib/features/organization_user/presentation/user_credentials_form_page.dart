import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/organization_user/domain/user_credentials.dart';
import 'package:algo_erp_front/features/organization_user/user_credentials_di.dart';
import 'package:algo_erp_front/features/organization_user/user_credentials_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UserCredentialsFormPage extends StatelessWidget {
  const UserCredentialsFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<UserCredentials, int>>(
      create: (_) => createUserCredentialsRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          void refreshListAndReturn() {
            userCredentialsCrudBloc(context).add(const CrudRefreshRequested());
            context.go(userCredentialsManifest.resourcePath);
          }

          final surface = MasterFormSurface<UserCredentials, int>(
            manifest: userCredentialsManifest,
            mode: mode,
            idOf: (u) => u.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(userCredentialsManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: mode == FormMode.edit
                ? BlocProvider<DetailBloc<UserCredentials, int>>(
                    create: (ctx) => DetailBloc<UserCredentials, int>(
                      repository: ctx.read<Repository<UserCredentials, int>>(),
                      id: entityId!,
                    )..add(const DetailLoadRequested()),
                    child: surface,
                  )
                : surface,
          );
        },
      ),
    );
  }
}
