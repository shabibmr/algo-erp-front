import 'package:algo_erp_front/features/accounts_account_group/data/account_group_dto.dart';
import 'package:algo_erp_front/features/accounts_account_group/data/account_group_mapper.dart';
import 'package:algo_erp_front/features/accounts_account_group/domain/account_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = AccountGroupMapper();

  test("AccountGroupDto.fromJson reads the backend's wire casing", () {
    final dto = AccountGroupDto.fromJson(const {
      'id': 1,
      'group_code': 'CA-001',
      'Group_Name': 'Current Assets',
      'parent_group_id': 9,
      'is_system_defined': true,
      'full_path': 'Assets / Current Assets',
      'depth': 1,
    });

    expect(dto.id, 1);
    expect(dto.groupCode, 'CA-001');
    expect(dto.groupName, 'Current Assets');
    expect(dto.parentGroupId, 9);
    expect(dto.isSystemDefined, isTrue);
    expect(dto.fullPath, 'Assets / Current Assets');
    expect(dto.depth, 1);
  });

  test('AccountGroupDto.fromJson tolerates optional code', () {
    final dto = AccountGroupDto.fromJson(const {'id': 2, 'Group_Name': 'Misc'});
    expect(dto.groupCode, isNull);
    expect(dto.parentGroupId, isNull);
    expect(dto.isSystemDefined, isFalse);
  });

  test('AccountGroupMapper.toEntity produces clean names + parent', () {
    const dto = AccountGroupDto(
      id: 1,
      groupName: 'Current Assets',
      groupCode: 'CA-001',
      parentGroupId: 9,
      isSystemDefined: true,
      fullPath: 'Assets / Current Assets',
      depth: 1,
    );
    final entity = mapper.toEntity(dto);

    expect(
      entity,
      const AccountGroup(
        id: 1,
        name: 'Current Assets',
        code: 'CA-001',
        parentGroupId: 9,
        isSystemDefined: true,
        fullPath: 'Assets / Current Assets',
        depth: 1,
      ),
    );
  });

  test('AccountGroupMapper.toDto.toJson sends parent_group_id', () {
    const group = AccountGroup(id: 1, name: 'Misc', parentGroupId: 3);
    expect(mapper.toDto(group).toJson(), {
      'Group_Name': 'Misc',
      'parent_group_id': 3,
      'is_system_defined': false,
    });
  });

  test('AccountGroupMapper.toDto.toJson omits empty code', () {
    const group = AccountGroup(id: 1, name: 'Misc');
    expect(mapper.toDto(group).toJson(), {
      'Group_Name': 'Misc',
      'parent_group_id': null,
      'is_system_defined': false,
    });
  });

  test('round-trip preserves core fields (path is read-only on write)', () {
    const group = AccountGroup(
      id: 5,
      name: 'Liabilities',
      code: 'L-01',
      parentGroupId: 2,
    );
    final back = mapper.toEntity(mapper.toDto(group));
    expect(back.id, group.id);
    expect(back.name, group.name);
    expect(back.code, group.code);
    expect(back.parentGroupId, group.parentGroupId);
  });
}
