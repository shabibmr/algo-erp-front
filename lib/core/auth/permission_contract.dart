/// The five actions the backend gates every route on
/// (`authorize(moduleName, action)` — see api-contract.md / RBAC).
///
/// Maps 1:1 to the backend permission columns:
/// `Allow_Create/Read/Update/Delete/Share`.
enum PermissionAction { create, read, update, delete, share }

/// Answers "may the current user do X to module Y?" for the whole UI.
///
/// This is an **interface** on purpose. Track B implements it against the
/// role's permission matrix — but there is currently no endpoint to read that
/// matrix (see `docs/backend-suggestions.md` BE-001), so the first
/// implementation fails **open** and leans on server `403`s. When BE-001 lands,
/// a real implementation drops in behind this same interface with zero changes
/// to any `PermissionGate` or `RbacMixin` consumer.
// ignore: one_member_abstracts — interface with several implementations.
abstract interface class PermissionService {
  /// [module] is the PascalCase backend module name (e.g. `Brand`,
  /// `SalesInvoice`). Returns whether [action] is permitted.
  bool can(String module, PermissionAction action);
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
