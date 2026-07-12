import 'package:algo_erp_front/core/manifest/field_spec.dart' show ColumnAlign;
import 'package:algo_erp_front/core/theme/motion_tokens.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// One column of a [LedgerTable].
@immutable
class LedgerColumn<T> {
  const LedgerColumn({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
    this.minWidth = 96,
    this.align = ColumnAlign.start,
    this.mono = false,
    this.primary = false,
  });

  final String label;
  final Widget Function(BuildContext context, T item) cellBuilder;

  /// This column's share of the width left over once every column has its
  /// [minWidth].
  final int flex;
  final double minWidth;

  final ColumnAlign align;

  /// Render text cells in tabular mono figures — for codes, quantities, money.
  final bool mono;

  /// The identity column: the value a clerk scans for, set in ink at `w600`.
  final bool primary;
}

/// The ledger sheet's rows.
///
/// Columns flex to fill the full width they're given, so the table is the
/// sheet rather than a narrow island inside it; it falls back to horizontal
/// scrolling only when the columns' own minimum widths genuinely don't fit.
///
/// Rows are separated by a faint rule, and **every fifth rule is drawn at full
/// strength** — the way a paper ledger pad rules in fives so the eye can count
/// down a column without losing its place. Hovering or focusing a row lights a
/// lagoon edge in its left gutter, like a finger tracking the page. The rhythm
/// and both colors come from `AppTokens.ledger`.
///
/// The header row is a sibling of the scrolling list, not an item in it, so it
/// stays put while rows scroll under it.
class LedgerTable<T> extends StatelessWidget {
  const LedgerTable({
    required this.items,
    required this.columns,
    super.key,
    this.onTap,
    this.keyOf,
    this.footer,
  });

  final List<T> items;
  final List<LedgerColumn<T>> columns;
  final ValueChanged<T>? onTap;

  /// Stable key extractor (e.g. `(e) => e.id`) so rows keep their identity
  /// across rebuilds.
  final Object? Function(T item)? keyOf;

  /// Pinned below the last row — used for the load-more indicator.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final gap = tokens.spacing.md;
    final sidePadding = tokens.spacing.md;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chrome = sidePadding * 2 + gap * (columns.length - 1);
        final available = constraints.maxWidth - chrome;
        final minTotal = columns.fold<double>(0, (sum, c) => sum + c.minWidth);
        final scrolls = available < minTotal;

        // Every column gets its minimum first; whatever is left over is shared
        // out by flex. That fills the sheet edge to edge without ever starving
        // a column below the width its content needs.
        final totalFlex = columns.fold<int>(0, (sum, c) => sum + c.flex);
        final surplus = scrolls ? 0.0 : available - minTotal;
        final widths = [
          for (final column in columns)
            column.minWidth +
                (totalFlex == 0 ? 0 : surplus * column.flex / totalFlex),
        ];

        // Inside a sheet the ledger fills the height it's given and scrolls its
        // own rows. Handed an unbounded height (a gallery, a page that scrolls
        // as a whole) it hugs its rows instead of throwing.
        final bounded = constraints.hasBoundedHeight;

        final rows = ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: !bounded,
          physics: bounded ? null : const NeverScrollableScrollPhysics(),
          itemCount: items.length + (footer == null ? 0 : 1),
          itemBuilder: (context, index) {
            if (index >= items.length) return footer;
            final item = items[index];
            return _LedgerRow<T>(
              key: keyOf == null ? null : ValueKey(keyOf!(item)),
              item: item,
              index: index,
              isLast: index == items.length - 1,
              columns: columns,
              widths: widths,
              gap: gap,
              sidePadding: sidePadding,
              onTap: onTap,
            );
          },
        );

        final table = Column(
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LedgerHeader<T>(
              columns: columns,
              widths: widths,
              gap: gap,
              sidePadding: sidePadding,
            ),
            if (bounded) Expanded(child: rows) else rows,
          ],
        );

        if (!scrolls) return table;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minTotal + chrome, child: table),
        );
      },
    );
  }
}

/// Builds the cells of one row (or the header), laid out to [widths].
List<Widget> _cells({
  required List<Widget> children,
  required List<double> widths,
  required double gap,
}) => [
  for (final (index, child) in children.indexed) ...[
    if (index > 0) SizedBox(width: gap),
    SizedBox(width: widths[index], child: child),
  ],
];

class _LedgerHeader<T> extends StatelessWidget {
  const _LedgerHeader({
    required this.columns,
    required this.widths,
    required this.gap,
    required this.sidePadding,
  });

  final List<LedgerColumn<T>> columns;
  final List<double> widths;
  final double gap;
  final double sidePadding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: tokens.brand.inkMuted,
      letterSpacing: 0.08 * 11,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sidePadding,
        vertical: tokens.spacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.ledger.ruleStrong)),
      ),
      child: Row(
        children: _cells(
          widths: widths,
          gap: gap,
          children: [
            for (final column in columns)
              Align(
                alignment: column.align == ColumnAlign.end
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Text(
                  column.label.toUpperCase(),
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LedgerRow<T> extends StatefulWidget {
  const _LedgerRow({
    required this.item,
    required this.index,
    required this.isLast,
    required this.columns,
    required this.widths,
    required this.gap,
    required this.sidePadding,
    required this.onTap,
    super.key,
  });

  final T item;
  final int index;
  final bool isLast;
  final List<LedgerColumn<T>> columns;
  final List<double> widths;
  final double gap;
  final double sidePadding;
  final ValueChanged<T>? onTap;

  @override
  State<_LedgerRow<T>> createState() => _LedgerRowState<T>();
}

class _LedgerRowState<T> extends State<_LedgerRow<T>> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ledger = tokens.ledger;
    final lit = _hovered || _focused;

    // The ledger rules in fives: a faint line between rows, a full-strength one
    // closing each group so the eye can count down the column.
    final endsGroup = (widget.index + 1) % ledger.groupEvery == 0;
    final rule = endsGroup ? ledger.ruleStrong : ledger.ruleFaint;

    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : MotionTokens.hoverPress;

    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap == null ? null : () => widget.onTap!(widget.item),
        onFocusChange: (value) => setState(() => _focused = value),
        // The wash and gutter below already read as hover/focus; Material's own
        // overlay on top of them just muddies the paper.
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: AnimatedContainer(
          duration: duration,
          curve: MotionTokens.standardCurve,
          constraints: BoxConstraints(minHeight: ledger.rowMinHeight),
          padding: EdgeInsetsDirectional.only(
            // The gutter is always reserved, lit or not, so text never shifts.
            start: widget.sidePadding - ledger.gutterWidth,
            end: widget.sidePadding,
            top: tokens.spacing.sm,
            bottom: tokens.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: lit ? ledger.rowHover : Colors.transparent,
            border: BorderDirectional(
              start: BorderSide(
                color: lit ? ledger.gutter : Colors.transparent,
                width: ledger.gutterWidth,
              ),
              bottom: widget.isLast ? BorderSide.none : BorderSide(color: rule),
            ),
          ),
          child: Row(
            children: _cells(
              widths: widget.widths,
              gap: widget.gap,
              children: [
                for (final column in widget.columns)
                  DefaultTextStyle(
                    style: _cellStyle(context, column),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: Align(
                      alignment: column.align == ColumnAlign.end
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: column.cellBuilder(context, widget.item),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _cellStyle(BuildContext context, LedgerColumn<T> column) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final base = column.mono
        ? tokens.figures
        : textTheme.bodyMedium ?? const TextStyle();
    return base.copyWith(
      color: tokens.brand.ink,
      fontWeight: column.primary ? FontWeight.w600 : base.fontWeight,
    );
  }
}
