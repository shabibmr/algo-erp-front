import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:equatable/equatable.dart';

/// Wire shape of one permission row, as returned by `GET /auth/permissions`
/// (`data.permissions[]`) and embedded in `GET /auth/me` (`data.permissions[]`).
///
/// Field names are the backend's verbatim — `module_name` snake_case, the
/// `Allow_*` flags PascalCase — matching `permissionsSchema` in
/// `organization.schema.ts`.
class PermissionDto extends Equatable {
  const PermissionDto({
    required this.moduleName,
    this.allowCreate = false,
    this.allowRead = false,
    this.allowUpdate = false,
    this.allowDelete = false,
    this.allowShare = false,
  });

  factory PermissionDto.fromJson(Map<String, dynamic> json) {
    return PermissionDto(
      moduleName: json['module_name'] as String? ?? '',
      allowCreate: _bool(json['Allow_Create']),
      allowRead: _bool(json['Allow_Read']),
      allowUpdate: _bool(json['Allow_Update']),
      allowDelete: _bool(json['Allow_Delete']),
      allowShare: _bool(json['Allow_Share']),
    );
  }

  final String moduleName;
  final bool allowCreate;
  final bool allowRead;
  final bool allowUpdate;
  final bool allowDelete;
  final bool allowShare;

  Map<String, dynamic> toJson() => {
    'module_name': moduleName,
    'Allow_Create': allowCreate,
    'Allow_Read': allowRead,
    'Allow_Update': allowUpdate,
    'Allow_Delete': allowDelete,
    'Allow_Share': allowShare,
  };

  ModulePermissions toEntity() => ModulePermissions(
    module: moduleName,
    create: allowCreate,
    read: allowRead,
    update: allowUpdate,
    delete: allowDelete,
    share: allowShare,
  );

  /// The columns are `Boolean` in Prisma but nullable, and older rows can carry
  /// a 0/1 tinyint — so coerce rather than cast.
  static bool _bool(Object? raw) => switch (raw) {
    final bool value => value,
    final num value => value != 0,
    _ => false,
  };

  @override
  List<Object?> get props => [
    moduleName,
    allowCreate,
    allowRead,
    allowUpdate,
    allowDelete,
    allowShare,
  ];
}
