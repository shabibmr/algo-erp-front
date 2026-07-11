import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// The set of voucher lifecycle states [StatusChip] knows how to color via
/// `AppTokens.voucherStatusColors`. Add a new status here (not as a raw
/// color) so every chip stays in sync with the token file.
enum EntityStatus { draft, approved, posted, cancelled, rejected, pendingSync }

/// A colored pill for an entity/voucher status, styled from
/// `AppTokens.voucherStatusColors` — never a hardcoded color — so light/dark
/// and future palette tweaks apply everywhere at once.
///
/// ```dart
/// StatusChip(status: EntityStatus.posted, label: 'Posted')
/// ```
class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, required this.label, super.key});

  final EntityStatus status;
  final String label;

  Color _colorOf(BuildContext context) {
    final colors = context.tokens.voucherStatusColors;
    return switch (status) {
      EntityStatus.draft => colors.draft,
      EntityStatus.approved => colors.approved,
      EntityStatus.posted => colors.posted,
      EntityStatus.cancelled => colors.cancelled,
      EntityStatus.rejected => colors.rejected,
      EntityStatus.pendingSync => colors.pendingSync,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(context);
    final tokens = context.tokens;
    return Chip(
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radii.full),
      ),
      avatar: status == EntityStatus.pendingSync
          ? Icon(Icons.sync, size: 16, color: color)
          : null,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsetsDirectional.symmetric(horizontal: tokens.spacing.xs),
    );
  }
}
