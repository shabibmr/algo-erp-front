import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/accounts_account_group/data/account_group_dto.dart';
import 'package:algo_erp_front/features/accounts_account_group/domain/account_group.dart';

class AccountGroupMapper implements Mapper<AccountGroupDto, AccountGroup> {
  const AccountGroupMapper();

  @override
  AccountGroup toEntity(AccountGroupDto dto) => AccountGroup(
    id: dto.id,
    name: dto.groupName,
    code: dto.groupCode,
    parentGroupId: dto.parentGroupId,
    isSystemDefined: dto.isSystemDefined,
    fullPath: dto.fullPath,
    depth: dto.depth,
  );

  @override
  AccountGroupDto toDto(AccountGroup entity) => AccountGroupDto(
    id: entity.id,
    groupName: entity.name,
    groupCode: entity.code,
    parentGroupId: entity.parentGroupId,
    isSystemDefined: entity.isSystemDefined,
    fullPath: entity.fullPath,
    depth: entity.depth,
  );
}
