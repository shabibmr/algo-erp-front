import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// One column of a [LineItemGrid] row: a label plus a builder that produces
/// the editing widget (typically an `AppDecimalField`/`AppDropdownField`/
/// `FkLookupField`) for a given row. The builder receives the row's index
/// so it can report changes back via [LineItemGrid.onChanged] with the
/// right position.
@immutable
class LineItemColumn<R> {
  const LineItemColumn({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
  });

  final String label;
  final Widget Function(BuildContext context, R row, int index) cellBuilder;
  final int flex;
}

/// An editable grid of voucher line items: one row per `R`, with add/remove
/// affordances and column headers, composed entirely from caller-supplied
/// field widgets — this widget owns layout only, never field state. The
/// caller's bloc/form owns `rows`; [onChanged] is called with the full,
/// updated list on every add/remove so it stays a controlled component.
///
/// ```dart
/// LineItemGrid<VoucherLine>(
///   rows: lines,
///   columns: [
///     LineItemColumn(
///       label: 'Item',
///       cellBuilder: (context, row, i) => FkLookupField<Item>(...),
///     ),
///     LineItemColumn(
///       label: 'Qty',
///       cellBuilder: (context, row, i) => AppDecimalField(...),
///     ),
///   ],
///   onChanged: (updated) => setState(() => lines = updated),
///   newRow: () => VoucherLine.empty(),
/// )
/// ```
class LineItemGrid<R> extends StatelessWidget {
  const LineItemGrid({
    required this.rows,
    required this.columns,
    required this.onChanged,
    super.key,
    this.newRow,
    this.keyOf,
    this.addLabel = 'Add line',
    this.enabled = true,
  });

  final List<R> rows;
  final List<LineItemColumn<R>> columns;
  final ValueChanged<List<R>> onChanged;

  /// Stable identity for a row, so its field widgets follow the row rather
  /// than the slot it happens to sit in. Without it rows are keyed by index:
  /// remove the middle of three and the third row's element — text and all —
  /// slides up into the vacated position. Supply this whenever `R` carries an
  /// id; omit it for grids that only ever append.
  final Object Function(R row, int index)? keyOf;

  /// Factory for a fresh row, wired to the add-row button. Omit to hide
  /// the add button (e.g. a read-only/approval view of the same grid).
  final R Function()? newRow;
  final String addLabel;
  final bool enabled;

  void _removeAt(int index) {
    final updated = List<R>.of(rows)..removeAt(index);
    onChanged(updated);
  }

  void _add() {
    final factory = newRow;
    if (factory == null) return;
    onChanged(List<R>.of(rows)..add(factory()));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (context.isDesktop || context.isTablet)
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: tokens.spacing.xs),
            child: Row(
              children: [
                for (final column in columns)
                  Expanded(
                    flex: column.flex,
                    child: Text(
                      column.label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                const SizedBox(width: 48), // remove-button gutter
              ],
            ),
          ),
        for (var i = 0; i < rows.length; i++)
          KeyedSubtree(
            key: ValueKey<Object>(keyOf?.call(rows[i], i) ?? i),
            child: Padding(
              padding: EdgeInsetsDirectional.only(bottom: tokens.spacing.sm),
              child: Row(
                children: [
                  for (final column in columns)
                    Expanded(
                      flex: column.flex,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: tokens.spacing.xs,
                        ),
                        child: column.cellBuilder(context, rows[i], i),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Remove row',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: enabled ? () => _removeAt(i) : null,
                  ),
                ],
              ),
            ),
          ),
        if (newRow != null)
          Padding(
            padding: EdgeInsetsDirectional.only(top: tokens.spacing.xs),
            child: OutlinedButton.icon(
              onPressed: enabled ? _add : null,
              icon: const Icon(Icons.add),
              label: Text(addLabel),
            ),
          ),
      ],
    );
  }
}
