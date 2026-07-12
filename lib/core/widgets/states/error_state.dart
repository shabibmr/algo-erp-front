import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// Friendly error placeholder shown when a `ViewState` resolves to
/// `ViewError`. Renders [Failure.message] plus an icon chosen by failure
/// kind, and an optional retry button that hands control back to the
/// caller (re-dispatch a bloc event, re-run a future, etc.) — this widget
/// never knows *how* to retry, only *that* the caller wants to offer it.
class ErrorState extends StatelessWidget {
  const ErrorState({required this.failure, super.key, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  IconData get _icon => switch (failure) {
    NetworkFailure() => Icons.wifi_off_outlined,
    TimeoutFailure() => Icons.hourglass_disabled_outlined,
    UnauthorizedFailure() || ForbiddenFailure() => Icons.lock_outline,
    ValidationFailure() => Icons.report_gmailerrorred_outlined,
    NotFoundFailure() => Icons.search_off_outlined,
    ConflictFailure() => Icons.sync_problem_outlined,
    ServerFailure() => Icons.dns_outlined,
    CacheFailure() => Icons.storage_outlined,
    UnknownFailure() => Icons.error_outline,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 48, color: tokens.semanticColors.danger),
            SizedBox(height: tokens.spacing.md),
            Text(
              failure.message.isNotEmpty ? failure.message : context.l10n.error,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: tokens.spacing.md),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.retry),
                style: FilledButton.styleFrom(
                  foregroundColor: colors.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
