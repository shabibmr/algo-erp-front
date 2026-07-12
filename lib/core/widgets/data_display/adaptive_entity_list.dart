import 'package:algo_erp_front/core/manifest/field_spec.dart' show ColumnAlign;
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/data_display/ledger_table.dart';
import 'package:flutter/material.dart';

/// One column of an [AdaptiveEntityList].
///
/// [cellBuilder] gets the row item and returns the cell widget; [label] is the
/// column header. The presentation flags mirror `LedgerColumn`'s and are what
/// the table and the mobile cards both read.
@immutable
class EntityColumn<T> {
  const EntityColumn({
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

  /// Share of the width left over once every column has its [minWidth].
  final int flex;
  final double minWidth;

  final ColumnAlign align;

  /// Render text cells in tabular mono figures — codes, quantities, money.
  final bool mono;

  /// The identity column: what a clerk scans for. Set in ink at `w600`, and
  /// used as the title of the mobile index card.
  final bool primary;
}

/// Renders a list of entities as a ledger sheet on tablet/desktop and as index
/// cards on mobile — the one adaptive list shape every master list screen
/// reuses instead of hand-rolling its own breakpoint switch.
///
/// Both renderings are driven by the same [columns], so a screen declares its
/// data once. Pass [cardBuilder] only to override the default index card.
///
/// ```dart
/// AdaptiveEntityList<Brand>(
///   items: brands,
///   keyOf: (b) => b.id,
///   columns: [
///     EntityColumn(label: 'Code', mono: true, primary: true,
///         cellBuilder: (_, b) => Text(b.code)),
///     EntityColumn(label: 'Name', flex: 3,
///         cellBuilder: (_, b) => Text(b.name)),
///   ],
///   onTap: (b) => context.push('/inventory/brand/${b.id}'),
/// )
/// ```
class AdaptiveEntityList<T> extends StatelessWidget {
  const AdaptiveEntityList({
    required this.items,
    required this.columns,
    super.key,
    this.cardBuilder,
    this.onTap,
    this.keyOf,
    this.footer,
  });

  final List<T> items;
  final List<EntityColumn<T>> columns;

  /// Overrides the default mobile index card. Leave null and the card is built
  /// from [columns]: the primary column as the card's title, the rest as quiet
  /// label/value lines.
  final Widget Function(BuildContext context, T item)? cardBuilder;

  final ValueChanged<T>? onTap;

  /// Stable key extractor (e.g. `(e) => e.id`) so rows and cards keep their
  /// identity across rebuilds.
  final Object? Function(T item)? keyOf;

  /// Pinned below the last row/card — used for the load-more indicator.
  final Widget? footer;

  /// The column a clerk scans for: whichever is flagged [EntityColumn.primary],
  /// else the first.
  int get _primaryIndex {
    final flagged = columns.indexWhere((c) => c.primary);
    return flagged == -1 ? 0 : flagged;
  }

  @override
  Widget build(BuildContext context) {
    return context.hasPersistentNav ? _buildLedger(context) : _cards(context);
  }

  Widget _buildLedger(BuildContext context) {
    final primary = _primaryIndex;
    return LedgerTable<T>(
      items: items,
      onTap: onTap,
      keyOf: keyOf,
      footer: footer,
      columns: [
        for (final (index, column) in columns.indexed)
          LedgerColumn<T>(
            label: column.label,
            cellBuilder: column.cellBuilder,
            flex: column.flex,
            minWidth: column.minWidth,
            align: column.align,
            mono: column.mono,
            primary: column.primary || index == primary,
          ),
      ],
    );
  }

  Widget _cards(BuildContext context) {
    final tokens = context.tokens;
    return ListView.separated(
      padding: EdgeInsets.all(tokens.spacing.md),
      itemCount: items.length + (footer == null ? 0 : 1),
      separatorBuilder: (_, _) => SizedBox(height: tokens.spacing.sm),
      itemBuilder: (context, index) {
        if (index >= items.length) return footer;
        final item = items[index];
        return _IndexCard<T>(
          key: keyOf == null ? null : ValueKey(keyOf!(item)),
          item: item,
          columns: columns,
          primaryIndex: _primaryIndex,
          cardBuilder: cardBuilder,
          onTap: onTap,
        );
      },
    );
  }
}

/// The mobile rendering of a row: the identity value as a heading, the
/// remaining columns as quiet label/value lines underneath. A card, not a
/// squeezed table.
class _IndexCard<T> extends StatelessWidget {
  const _IndexCard({
    required this.item,
    required this.columns,
    required this.primaryIndex,
    required this.cardBuilder,
    required this.onTap,
    super.key,
  });

  final T item;
  final List<EntityColumn<T>> columns;
  final int primaryIndex;
  final Widget Function(BuildContext context, T item)? cardBuilder;
  final ValueChanged<T>? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    final content =
        cardBuilder?.call(context, item) ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            DefaultTextStyle(
              style: textTheme.titleMedium!.copyWith(color: tokens.brand.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: columns[primaryIndex].cellBuilder(context, item),
            ),
            for (final (index, column) in columns.indexed)
              if (index != primaryIndex)
                Padding(
                  padding: EdgeInsets.only(top: tokens.spacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 104,
                        child: Text(
                          column.label,
                          style: textTheme.bodySmall?.copyWith(
                            color: tokens.brand.inkMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: DefaultTextStyle(
                          style:
                              (column.mono
                                      ? tokens.figures
                                      : textTheme.bodyMedium!)
                                  .copyWith(color: tokens.brand.ink),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          child: column.cellBuilder(context, item),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        );

    return Material(
      color: tokens.brand.paper,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: tokens.brand.mist),
        borderRadius: BorderRadius.circular(tokens.radii.lg),
      ),
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(item),
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.md),
          child: content,
        ),
      ),
    );
  }
}
