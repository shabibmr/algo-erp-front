import 'package:equatable/equatable.dart';

/// Wire shape of `/accounts/groups`, matching `account_groups` +
/// `accountGroupSchema`. List/get may include `full_path` / `depth`.
class AccountGroupDto extends Equatable {
  const AccountGroupDto({
    required this.id,
    required this.groupName,
    this.groupCode,
    this.parentGroupId,
    this.isSystemDefined = false,
    this.fullPath,
    this.depth,
  });

  factory AccountGroupDto.fromJson(Map<String, dynamic> json) =>
      AccountGroupDto(
        id: json['id'] as int,
        groupName: json['Group_Name'] as String,
        groupCode: json['group_code'] as String?,
        parentGroupId: json['parent_group_id'] as int?,
        isSystemDefined: json['is_system_defined'] as bool? ?? false,
        fullPath: json['full_path'] as String?,
        depth: json['depth'] as int?,
      );

  final int id;
  final String groupName;
  final String? groupCode;
  final int? parentGroupId;
  final bool isSystemDefined;
  final String? fullPath;
  final int? depth;

  /// `id`/timestamps and path fields are server-generated / read-only.
  Map<String, dynamic> toJson() => {
        'Group_Name': groupName,
        if (groupCode != null && groupCode!.isNotEmpty) 'group_code': groupCode,
        'parent_group_id': parentGroupId,
        'is_system_defined': isSystemDefined,
      };

  @override
  List<Object?> get props => [
        id,
        groupName,
        groupCode,
        parentGroupId,
        isSystemDefined,
        fullPath,
        depth,
      ];
}
