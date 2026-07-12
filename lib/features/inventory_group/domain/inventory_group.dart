import 'package:equatable/equatable.dart';

const _unset = Object();

/// Inventory group master — hard-deleted. Optional parent via
/// `FieldType.selfFk` (`parent_group_id`).
class InventoryGroup extends Equatable {
  const InventoryGroup({
    required this.id,
    required this.groupId,
    required this.name,
    this.code,
    this.parentGroupId,
    this.groupType,
    this.nameArabic,
    this.fullPath,
    this.depth,
  });

  final int id;

  /// Legacy unique string column `Group_ID` (required by API).
  final String groupId;
  final String name;
  final String? code;
  final int? parentGroupId;
  final String? groupType;
  final String? nameArabic;

  /// Server-computed path label (list/get only; not written).
  final String? fullPath;
  final int? depth;

  InventoryGroup copyWith({
    int? id,
    String? groupId,
    String? name,
    Object? code = _unset,
    Object? parentGroupId = _unset,
    Object? groupType = _unset,
    Object? nameArabic = _unset,
    Object? fullPath = _unset,
    Object? depth = _unset,
  }) =>
      InventoryGroup(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        name: name ?? this.name,
        code: identical(code, _unset) ? this.code : code as String?,
        parentGroupId: identical(parentGroupId, _unset)
            ? this.parentGroupId
            : parentGroupId as int?,
        groupType: identical(groupType, _unset)
            ? this.groupType
            : groupType as String?,
        nameArabic: identical(nameArabic, _unset)
            ? this.nameArabic
            : nameArabic as String?,
        fullPath:
            identical(fullPath, _unset) ? this.fullPath : fullPath as String?,
        depth: identical(depth, _unset) ? this.depth : depth as int?,
      );

  @override
  List<Object?> get props => [
        id,
        groupId,
        name,
        code,
        parentGroupId,
        groupType,
        nameArabic,
        fullPath,
        depth,
      ];
}
