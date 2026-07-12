import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_user/data/user_credentials_repository.dart';
import 'package:algo_erp_front/features/organization_user/domain/user_credentials.dart';
import 'package:algo_erp_front/features/organization_user/user_credentials_manifest.dart';
import 'package:flutter/widgets.dart';

Repository<UserCredentials, int> createUserCredentialsRepository(
  DioClient client,
) {
  return UserCredentialsRepository(client);
}

CrudBloc<UserCredentials, int, void> createUserCredentialsCrudBloc(
  DioClient client,
) {
  return CrudBloc<UserCredentials, int, void>(
    repository: createUserCredentialsRepository(client),
    idOf: (u) => u.id,
  );
}

CrudBloc<UserCredentials, int, void> userCredentialsCrudBloc(
  BuildContext context,
) {
  return CrudBlocScope.of<UserCredentials, int, void>(
    context,
    userCredentialsManifest.id,
    () => createUserCredentialsCrudBloc(getIt<DioClient>()),
  );
}
