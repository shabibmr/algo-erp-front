import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:injectable/injectable.dart';

/// Interim [PermissionService] that permits **everything**.
///
/// There is no endpoint to read a role's permission matrix yet (see
/// `docs/backend-suggestions.md` BE-001), so the client cannot know locally
/// what the current user may do. Rather than hide functionality we might in
/// fact be allowed to use, we fail **open**: every gate shows, and the
/// server's `403` (mapped to `Failure.forbidden`) stays the real enforcement
/// point. When BE-001 lands, a matrix-backed implementation drops in behind
/// this same interface with zero changes to any `PermissionGate`/`RbacMixin`
/// consumer.
@LazySingleton(as: PermissionService)
class FailOpenPermissionService implements PermissionService {
  const FailOpenPermissionService();

  @override
  bool can(String module, PermissionAction action) => true;
}
