import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/config/app_config.dart';
import 'package:injectable/injectable.dart';

/// The real, matrix-backed [PermissionService].
///
/// Holds the signed-in role's permission rows (loaded by the auth layer from
/// `GET /auth/permissions`, or off the `permissions` array `GET /auth/me`
/// already embeds) and answers [can] from them.
///
/// **Fails closed** in normal builds. An unknown module, or a matrix that
/// hasn't been loaded at all, denies — deliberately mirroring the server,
/// which treats a missing `user_access_permissions` row as all-false
/// (`authorize.ts`).
///
/// **Dev full access:** when [AppConfig.shouldGrantFullAccess] is true (dev
/// flavor + `DEV_FULL_ACCESS`), every check returns true so local testing is
/// not blocked by an incomplete role matrix. Server `authorize()` still
/// enforces real rights on API calls.
class MatrixPermissionService
    implements PermissionService, PermissionMatrixSink {
  final Map<String, ModulePermissions> _matrix = {};

  @override
  void load(Iterable<ModulePermissions> permissions) {
    _matrix
      ..clear()
      ..addEntries(permissions.map((p) => MapEntry(p.module, p)));
  }

  @override
  void clear() => _matrix.clear();

  @override
  bool can(String module, PermissionAction action) {
    if (AppConfig.shouldGrantFullAccess) return true;
    return _matrix[module]?.allows(action) ?? false;
  }
}

/// Registers one [MatrixPermissionService] instance under both of its
/// interfaces, so the auth layer's writes through [PermissionMatrixSink] are
/// the same object the UI reads through [PermissionService].
@module
abstract class PermissionModule {
  @lazySingleton
  MatrixPermissionService matrixPermissionService() =>
      MatrixPermissionService();

  @lazySingleton
  PermissionService permissionService(MatrixPermissionService service) =>
      service;

  @lazySingleton
  PermissionMatrixSink permissionMatrixSink(MatrixPermissionService service) =>
      service;
}
