import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Binds Ctrl/Cmd+N to a list page's "create new" action.
///
/// Same pattern as the shell's Ctrl/Cmd+K command-palette binding: a
/// [CallbackShortcuts] layer that fires while focus is inside this subtree
/// (the list page). No-ops when [onCreate] is null or the user lacks create
/// on [module] — matching the create button's [PermissionGate].
class CreateNewShortcuts extends StatelessWidget {
  const CreateNewShortcuts({
    required this.module,
    required this.child,
    super.key,
    this.onCreate,
  });

  /// Backend RBAC module string — same one the create button's gate uses.
  final String module;

  /// Invoked on Ctrl/Cmd+N. Null means this list has no create action
  /// (e.g. audit log), so the binding is not registered.
  final VoidCallback? onCreate;

  final Widget child;

  /// Platform-aware label for tooltips, e.g. `Ctrl+N` or `⌘N`.
  static String get shortcutLabel {
    final isApple =
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return isApple ? '⌘N' : 'Ctrl+N';
  }

  @override
  Widget build(BuildContext context) {
    final create = onCreate;
    if (create == null) return child;

    final allowed = getIt<PermissionService>().can(
      module,
      PermissionAction.create,
    );
    if (!allowed) return child;

    // Autofocus so the binding is live as soon as the list mounts, even
    // before the user tabs into search. skipTraversal keeps it out of the
    // tab order so it doesn't steal sequential focus from real fields.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): create,
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): create,
      },
      child: Focus(autofocus: true, skipTraversal: true, child: child),
    );
  }
}
