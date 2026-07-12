import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/accounts_account_group/data/account_group_dto.dart';
import 'package:algo_erp_front/features/accounts_account_group/data/account_group_mapper.dart';
import 'package:algo_erp_front/features/accounts_account_group/domain/account_group.dart';

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

CrudBloc<AccountGroup, int, void> createAccountGroupCrudBloc(
  DioClient client,
) {
  return CrudBloc<AccountGroup, int, void>(
    repository: createAccountGroupRepository(client),
    idOf: (group) => group.id,
  );
}
