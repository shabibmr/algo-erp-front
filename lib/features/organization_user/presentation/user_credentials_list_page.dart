import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
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
    return BlocProvider<CrudBloc<UserCredentials, int, void>>.value(
      value: userCredentialsCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<UserCredentials>(
          manifest: userCredentialsManifest,
          idOf: (u) => u.id,
          onCreate: () => context.push('/organization/users/new'),
          onTap: (u) => context.push('/organization/users/${u.id}'),
        ),
      ),
    );
  }
}
