import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/accounts_account_group/data/account_group_dto.dart';
import 'package:algo_erp_front/features/accounts_account_group/data/account_group_mapper.dart';
import 'package:algo_erp_front/features/accounts_account_group/domain/account_group.dart';
import 'package:flutter/widgets.dart';

const _accountGroupMapper = AccountGroupMapper();

/// Literal path so the selfFk parent picker can import this DI file without
/// a circular dependency on the manifest.
const accountGroupResourcePath = '/accounts/groups';

RemoteRepository<AccountGroup, int> createAccountGroupRepository(
  DioClient client,
) {
  return buildRepository<AccountGroup, int>(
    client: client,
    resourcePath: accountGroupResourcePath,
    decode: (json) =>
        _accountGroupMapper.toEntity(AccountGroupDto.fromJson(json)),
    encode: (group) => _accountGroupMapper.toDto(group).toJson(),
    idOf: (group) => group.id,
  );
}

CrudBloc<AccountGroup, int, void> createAccountGroupCrudBloc(DioClient client) {
  return CrudBloc<AccountGroup, int, void>(
    repository: createAccountGroupRepository(client),
    idOf: (group) => group.id,
  );
}

/// The one AccountGroup [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this — resolving
/// the bloc any other way gives the form a private instance the list never
/// sees, which is how created rows went missing.
///
/// Keyed by [accountGroupResourcePath] rather than the manifest id, because
/// this file deliberately does not import the manifest (see above).
CrudBloc<AccountGroup, int, void> accountGroupCrudBloc(BuildContext context) {
  return CrudBlocScope.of<AccountGroup, int, void>(
    context,
    accountGroupResourcePath,
    () => createAccountGroupCrudBloc(getIt<DioClient>()),
  );
}
