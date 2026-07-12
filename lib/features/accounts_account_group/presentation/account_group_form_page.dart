import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/accounts_account_group/account_group_di.dart';
import 'package:algo_erp_front/features/accounts_account_group/account_group_manifest.dart';
import 'package:algo_erp_front/features/accounts_account_group/domain/account_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AccountGroupFormPage extends StatelessWidget {
  const AccountGroupFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<AccountGroup, int>>(
      create: (_) => createAccountGroupRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          // The surface has already persisted through the repository by the
          // time these fire, so the shared list bloc is told to refetch —
          // never CrudItemCreated/Updated/Deleted, which would write again.
          void refreshListAndReturn() {
            accountGroupCrudBloc(context).add(const CrudRefreshRequested());
            context.go(accountGroupManifest.resourcePath);
          }

          final surface = MasterFormSurface<AccountGroup, int>(
            manifest: accountGroupManifest,
            mode: mode,
            idOf: (g) => g.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(accountGroupManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: mode == FormMode.edit
                ? BlocProvider<DetailBloc<AccountGroup, int>>(
                    create: (ctx) => DetailBloc<AccountGroup, int>(
                      repository: ctx.read<Repository<AccountGroup, int>>(),
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
