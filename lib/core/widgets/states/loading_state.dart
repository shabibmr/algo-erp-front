import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// Skeleton-ish loading placeholder shown while a `ViewState` is
/// `ViewLoading`. Deliberately simple (shimmerless) — a centered spinner
/// plus the localized loading label — so it never fights a caller's own
/// list-skeleton if they choose to build one instead of using this default.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});

  /// Optional override for the localized default ("Loading...").
  final String? message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: tokens.spacing.md),
            Text(
              message ?? context.l10n.loading,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
