import 'package:equatable/equatable.dart';

const _unset = Object();

/// Account group master — hard-deleted (`AccountGroupRepository` sets
/// `softDeleteField: null`). Optional parent via `FieldType.selfFk`.
class AccountGroup extends Equatable {
  const AccountGroup({
    required this.id,
    required this.name,
    this.code,
    this.parentGroupId,
    this.isSystemDefined = false,
    this.fullPath,
    this.depth,
  });

  final int id;
  final String name;
  final String? code;
  final int? parentGroupId;
  final bool isSystemDefined;

  /// Server-computed path label (list/get only; not written).
  final String? fullPath;
  final int? depth;

  AccountGroup copyWith({
    int? id,
    String? name,
    Object? code = _unset,
    Object? parentGroupId = _unset,
    bool? isSystemDefined,
    Object? fullPath = _unset,
    Object? depth = _unset,
  }) =>
      AccountGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        code: identical(code, _unset) ? this.code : code as String?,
        parentGroupId: identical(parentGroupId, _unset)
            ? this.parentGroupId
            : parentGroupId as int?,
        isSystemDefined: isSystemDefined ?? this.isSystemDefined,
        fullPath:
            identical(fullPath, _unset) ? this.fullPath : fullPath as String?,
        depth: identical(depth, _unset) ? this.depth : depth as int?,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        parentGroupId,
        isSystemDefined,
        fullPath,
        depth,
      ];
}
