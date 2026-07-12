import 'package:algo_erp_front/features/inventory_group/data/inventory_group_dto.dart';
import 'package:algo_erp_front/features/inventory_group/data/inventory_group_mapper.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = InventoryGroupMapper();

  test("InventoryGroupDto.fromJson reads wire casing + full_path/depth", () {
    final dto = InventoryGroupDto.fromJson(const {
      'id': 3,
      'Group_ID': 'G-ROOT',
      'Group_Name': 'Finished goods',
      'group_code': 'FG',
      'parent_group_id': 1,
      'Parent_ID': '1',
      'Group_Type': 'Sales',
      'GroupNameArabic': 'بضاعة',
      'full_path': 'All / Finished goods',
      'depth': 1,
    });

    expect(dto.id, 3);
    expect(dto.groupId, 'G-ROOT');
    expect(dto.groupName, 'Finished goods');
    expect(dto.groupCode, 'FG');
    expect(dto.parentGroupId, 1);
    expect(dto.fullPath, 'All / Finished goods');
    expect(dto.depth, 1);
  });

  test('InventoryGroupMapper maps parent and path fields', () {
    const dto = InventoryGroupDto(
      id: 3,
      groupId: 'G1',
      groupName: 'Parts',
      parentGroupId: 1,
      fullPath: 'Root / Parts',
      depth: 1,
    );
    final entity = mapper.toEntity(dto);
    expect(entity.name, 'Parts');
    expect(entity.parentGroupId, 1);
    expect(entity.fullPath, 'Root / Parts');
    expect(entity.depth, 1);
  });

  test('toJson omits id and sends parent_group_id', () {
    const group = InventoryGroup(
      id: 3,
      groupId: 'G1',
      name: 'Parts',
      code: 'P',
      parentGroupId: 1,
    );
    final json = mapper.toDto(group).toJson();
    expect(json['Group_ID'], 'G1');
    expect(json['Group_Name'], 'Parts');
    expect(json['group_code'], 'P');
    expect(json['parent_group_id'], 1);
    expect(json['Parent_ID'], '1');
    expect(json.containsKey('id'), isFalse);
    expect(json.containsKey('full_path'), isFalse);
  });

  test('round-trip preserves core fields (path is read-only)', () {
    const group = InventoryGroup(
      id: 2,
      groupId: 'G2',
      name: 'Raw',
      parentGroupId: null,
      groupType: 'Purchase',
    );
    final back = mapper.toEntity(mapper.toDto(group));
    expect(back.id, group.id);
    expect(back.groupId, group.groupId);
    expect(back.name, group.name);
    expect(back.parentGroupId, group.parentGroupId);
    expect(back.groupType, group.groupType);
  });
}
