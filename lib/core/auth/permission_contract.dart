import 'package:equatable/equatable.dart';

/// The five actions the backend gates every route on
/// (`authorize(moduleName, action)` — see api-contract.md / RBAC).
///
/// Maps 1:1 to the backend permission columns:
/// `Allow_Create/Read/Update/Delete/Share`.
enum PermissionAction { create, read, update, delete, share }

/// One row of the role's permission matrix: what the role may do to one module.
///
/// Mirrors a `user_access_permissions` row. A module the role has **no** row
/// for is denied outright server-side (`authorize.ts` treats a missing row as
/// all-false), so the client must not invent a permissive default for it.
class ModulePermissions extends Equatable {
  const ModulePermissions({
    required this.module,
    this.create = false,
    this.read = false,
    this.update = false,
    this.delete = false,
    this.share = false,
  });

  /// PascalCase backend module name, e.g. `Brand`, `SalesInvoice`.
  final String module;
  final bool create;
  final bool read;
  final bool update;
  final bool delete;
  final bool share;

  bool allows(PermissionAction action) => switch (action) {
    PermissionAction.create => create,
    PermissionAction.read => read,
    PermissionAction.update => update,
    PermissionAction.delete => delete,
    PermissionAction.share => share,
  };

  @override
  List<Object?> get props => [module, create, read, update, delete, share];
}

/// Answers "may the current user do X to module Y?" for the whole UI.
///
/// Read-only on purpose: widgets and blocs ask, they never load. Loading is the
/// auth layer's job, through [PermissionMatrixSink].
// ignore: one_member_abstracts — interface with several implementations.
abstract interface class PermissionService {
  /// [module] is the PascalCase backend module name (e.g. `Brand`,
  /// `SalesInvoice`). Returns whether [action] is permitted.
  bool can(String module, PermissionAction action);
}

/// The write half of the permission matrix, kept separate from
/// [PermissionService] so only the auth layer can load or drop it — everything
/// else sees a read-only view.
abstract interface class PermissionMatrixSink {
  /// Replaces the matrix with the signed-in role's rows.
  void load(Iterable<ModulePermissions> permissions);

  /// Drops the matrix on sign-out, returning to a deny-all state.
  void clear();
}

/// Convenience gate for any class that already holds a [PermissionService]
/// (blocs, view models). Keeps permission checks terse and uniform:
/// `if (canCreate('Brand')) ...`.
mixin RbacMixin {
  PermissionService get permissionService;

  bool can(String module, PermissionAction action) =>
      permissionService.can(module, action);

  bool canCreate(String module) => can(module, PermissionAction.create);
  bool canRead(String module) => can(module, PermissionAction.read);
  bool canUpdate(String module) => can(module, PermissionAction.update);
  bool canDelete(String module) => can(module, PermissionAction.delete);
  bool canShare(String module) => can(module, PermissionAction.share);
}
