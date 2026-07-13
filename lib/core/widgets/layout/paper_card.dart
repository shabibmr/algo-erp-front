import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// The desk's paper-surfaced card shell — rounded, hairline-bordered,
/// barely elevated. Shared by the desk KPI tiles and the dashboard chart
/// cards so every "sheet on the desk" reads as the same material.
class PaperCard extends StatelessWidget {
  const PaperCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.lg),
      side: BorderSide(color: brand.mist),
    );

    return Material(
      color: brand.paper,
      elevation: tokens.elevation.level1,
      shadowColor: brand.ink.withValues(alpha: 0.06),
      shape: shape,
      child: Padding(padding: EdgeInsets.all(tokens.spacing.md), child: child),
    );
  }
}
