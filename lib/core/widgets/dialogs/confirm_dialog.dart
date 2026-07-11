import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// Shows a Material `AlertDialog` asking the user to confirm an action and
/// resolves to `true`/`false` (never null — dismissing counts as cancel).
///
/// [destructive] swaps the confirm button to the danger token color, for
/// actions like delete/cancel-voucher. Labels default to the platform's
/// OK/Cancel strings via [MaterialLocalizations] so callers only need to
/// override [confirmLabel]/[cancelLabel] for domain-specific wording (e.g.
/// "Delete", "Post voucher").
///
/// ```dart
/// final confirmed = await showConfirmDialog(
///   context,
///   title: 'Delete brand?',
///   message: 'This cannot be undone.',
///   confirmLabel: 'Delete',
///   destructive: true,
/// );
/// if (confirmed) { ... }
/// ```
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final materialL10n = MaterialLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel ?? materialL10n.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: dialogContext.tokens.semanticColors.danger,
                  foregroundColor: dialogContext.tokens.semanticColors.onDanger,
                )
              : null,
          child: Text(confirmLabel ?? materialL10n.okButtonLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
