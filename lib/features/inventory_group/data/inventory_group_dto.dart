import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/group`, matching `sales_inventory_groups` +
/// `inventoryGroupSchema`. List/get may include `full_path` / `depth`.
class InventoryGroupDto extends Equatable {
  const InventoryGroupDto({
    required this.id,
    required this.groupId,
    required this.groupName,
    this.groupCode,
    this.parentGroupId,
    this.parentId,
    this.groupType,
    this.groupNameArabic,
    this.fullPath,
    this.depth,
  });

  factory InventoryGroupDto.fromJson(Map<String, dynamic> json) =>
      InventoryGroupDto(
        id: json['id'] as int,
        groupId: json['Group_ID'] as String? ?? '',
        groupName: json['Group_Name'] as String? ?? '',
        groupCode: json['group_code'] as String?,
        parentGroupId: json['parent_group_id'] as int?,
        parentId: json['Parent_ID'] as String?,
        groupType: json['Group_Type'] as String?,
        groupNameArabic: json['GroupNameArabic'] as String?,
        fullPath: json['full_path'] as String?,
        depth: json['depth'] as int?,
      );

  final int id;
  final String groupId;
  final String groupName;
  final String? groupCode;
  final int? parentGroupId;
  final String? parentId;
  final String? groupType;
  final String? groupNameArabic;
  final String? fullPath;
  final int? depth;

  Map<String, dynamic> toJson() => {
    'Group_ID': groupId,
    'Group_Name': groupName,
    if (groupCode != null && groupCode!.isNotEmpty) 'group_code': groupCode,
    'parent_group_id': parentGroupId,
    if (parentId != null && parentId!.isNotEmpty) 'Parent_ID': parentId,
    if (groupType != null && groupType!.isNotEmpty) 'Group_Type': groupType,
    if (groupNameArabic != null && groupNameArabic!.isNotEmpty)
      'GroupNameArabic': groupNameArabic,
  };

  @override
  List<Object?> get props => [
    id,
    groupId,
    groupName,
    groupCode,
    parentGroupId,
    parentId,
    groupType,
    groupNameArabic,
    fullPath,
    depth,
  ];
}
