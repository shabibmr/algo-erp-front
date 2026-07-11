import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:injectable/injectable.dart';

/// The real, matrix-backed [PermissionService].
///
/// Holds the signed-in role's permission rows (loaded by the auth layer from
/// `GET /auth/permissions`, or off the `permissions` array `GET /auth/me`
/// already embeds) and answers [can] from them.
///
/// **Fails closed.** An unknown module, or a matrix that hasn't been loaded at
/// all, denies — deliberately mirroring the server, which treats a missing
/// `user_access_permissions` row as all-false (`authorize.ts`). Failing open
/// here would show buttons the server is going to `403`; failing closed can
/// only hide something the user could not have used anyway.
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
  bool can(String module, PermissionAction action) =>
      _matrix[module]?.allows(action) ?? false;
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
