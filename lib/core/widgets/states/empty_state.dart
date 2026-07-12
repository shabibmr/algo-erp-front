import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// Branded "nothing here yet" placeholder shown when a `ViewState` resolves
/// to `ViewEmpty`. Accepts an optional icon, message override, and a single
/// call-to-action button (e.g. "Create first record") so list screens don't
/// each reinvent an empty illustration.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  /// Optional override for the localized default ("Nothing here yet").
  final String? message;

  final IconData icon;

  /// Label for the optional CTA button. Ignored if [onAction] is null.
  final String? actionLabel;

  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            SizedBox(height: tokens.spacing.md),
            Text(
              message ?? context.l10n.empty,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: tokens.spacing.md),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
