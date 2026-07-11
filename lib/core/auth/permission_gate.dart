import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:flutter/widgets.dart';

/// Shows [child] only when the current user may perform [action] on [module];
/// otherwise renders [fallback] (an empty box by default).
///
/// Resolves the ambient [PermissionService] from `getIt`, so it drops in
/// anywhere in the tree without a provider. Today the service fails open
/// (BE-001), but every gated action/button should still be wrapped so real
/// gating "just works" the moment the permission-matrix endpoint exists.
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    required this.module,
    required this.action,
    required this.child,
    this.fallback,
    super.key,
  });

  /// PascalCase backend module name, e.g. `Brand`, `SalesInvoice`.
  final String module;
  final PermissionAction action;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final allowed = getIt<PermissionService>().can(module, action);
    return allowed ? child : (fallback ?? const SizedBox.shrink());
  }
}
