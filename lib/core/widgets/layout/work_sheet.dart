import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// A sheet of paper on the linen desk — the surface real work happens on.
///
/// Two jobs, one widget. With [fill] it stretches to the bottom of whatever
/// bounded height it's given, so a list of eight rows still reads as a full
/// page rather than eight rows floating on the canvas. Without it, it hugs its
/// content, which is how the form's index cards are built.
///
/// [toolbar] (or [title]) renders in a header band above a full-strength rule.
/// A sheet is also a [Material], so ink from rows and buttons inside it paints
/// on the paper rather than the canvas underneath.
class WorkSheet extends StatelessWidget {
  const WorkSheet({
    required this.child,
    super.key,
    this.title,
    this.toolbar,
    this.fill = true,
    this.padding = EdgeInsets.zero,
  }) : assert(
         title == null || toolbar == null,
         'A sheet has one header band: pass a title or a toolbar, not both.',
       );

  final Widget child;

  /// A section name for the header band (the index-card case).
  final String? title;

  /// Controls that act on this sheet's contents — search, filters, export.
  /// Rendered in the header band (the ledger case).
  final Widget? toolbar;

  /// Stretch to the full available height. Requires a bounded height (an
  /// `Expanded` parent). False makes the sheet hug its content.
  final bool fill;

  /// Padding around [child] only — the header band brings its own.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;

    final header = switch ((title, toolbar)) {
      (final String t, _) => Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spacing.md,
          tokens.spacing.md,
          tokens.spacing.md,
          tokens.spacing.sm,
        ),
        child: Text(t, style: Theme.of(context).textTheme.titleMedium),
      ),
      (_, final Widget t) => Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: t,
      ),
      _ => null,
    };

    final body = Padding(padding: padding, child: child);

    return Material(
      color: brand.paper,
      elevation: tokens.elevation.level0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: brand.mist),
        borderRadius: BorderRadius.circular(tokens.radii.lg),
      ),
      child: Column(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            header,
            Divider(height: 1, thickness: 1, color: brand.mist),
          ],
          if (fill) Expanded(child: body) else body,
        ],
      ),
    );
  }
}
