import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_group/data/inventory_group_dto.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';

class InventoryGroupMapper
    implements Mapper<InventoryGroupDto, InventoryGroup> {
  const InventoryGroupMapper();

  @override
  InventoryGroup toEntity(InventoryGroupDto dto) => InventoryGroup(
    id: dto.id,
    groupId: dto.groupId,
    name: dto.groupName,
    code: dto.groupCode,
    parentGroupId: dto.parentGroupId,
    groupType: dto.groupType,
    nameArabic: dto.groupNameArabic,
    fullPath: dto.fullPath,
    depth: dto.depth,
  );

  @override
  InventoryGroupDto toDto(InventoryGroup entity) => InventoryGroupDto(
    id: entity.id,
    groupId: entity.groupId,
    groupName: entity.name,
    groupCode: entity.code,
    parentGroupId: entity.parentGroupId,
    // Mirror parent int FK into legacy Parent_ID when present.
    parentId: entity.parentGroupId?.toString(),
    groupType: entity.groupType,
    groupNameArabic: entity.nameArabic,
    fullPath: entity.fullPath,
    depth: entity.depth,
  );
}
