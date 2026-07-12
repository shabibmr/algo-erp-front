import 'package:algo_erp_front/core/theme/motion_tokens.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// First-paint placeholder for a ledger sheet: ruled rows with the ink not yet
/// dry. Holds the sheet's shape while the page loads, so the surface doesn't
/// collapse to a spinner in an empty box and then jump when rows arrive.
///
/// Quiet by design — a slow pulse, no shimmer sweep.
class LedgerSkeleton extends StatefulWidget {
  const LedgerSkeleton({super.key, this.rows = 8, this.columns = 4});

  final int rows;
  final int columns;

  @override
  State<LedgerSkeleton> createState() => _LedgerSkeletonState();
}

class _LedgerSkeletonState extends State<LedgerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MotionTokens.slow * 2,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ledger = tokens.ledger;
    final still = MediaQuery.disableAnimationsOf(context);

    // Column widths that read like a table rather than a stack of equal bars:
    // a short code, a long name, then narrower trailing fields.
    double widthFactor(int column) => switch (column) {
      0 => 0.55,
      1 => 0.8,
      _ => 0.4,
    };

    // Announce the wait, not the placeholder bars.
    return Semantics(
      label: context.l10n.loading,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: still
              ? const AlwaysStoppedAnimation(0.5)
              : Tween<double>(begin: 0.35, end: 0.75).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: MotionTokens.standardCurve,
                  ),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // Hugs its rows, so the skeleton also works in a content-sized
            // sheet (the gallery) and not only in a full-height one.
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var row = 0; row < widget.rows; row++)
                Container(
                  height: ledger.rowMinHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spacing.md,
                    vertical: tokens.spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: (row + 1) % ledger.groupEvery == 0
                            ? ledger.ruleStrong
                            : ledger.ruleFaint,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (var column = 0; column < widget.columns; column++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: tokens.spacing.md,
                            ),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: FractionallySizedBox(
                                widthFactor: widthFactor(column),
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: tokens.brand.mist,
                                    borderRadius: BorderRadius.circular(
                                      tokens.radii.sm,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
