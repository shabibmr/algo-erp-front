import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

/// Factories for the two column shapes that repeat across every voucher form's
/// [LineItemGrid]: an editable [Decimal] cell and a read-only computed money
/// cell. They live here — not in `line_item_grid.dart`, which owns layout only
/// and never field state — so the grid stays agnostic while callers get a
/// one-liner per numeric column instead of a hand-rolled [AppDecimalField].

/// An editable, borderless [Decimal] column (Qty / Rate / Disc % / Tax %).
///
/// [get] reads the current value off a row; [set] writes a parsed value back
/// (typically `(r, v) => r.copyWith(field: v)`). [onChanged] receives the
/// cell's own `BuildContext` and the row index so the caller can dispatch a
/// positional update event against its bloc. When the field parses to null
/// (empty box), [fallback] is substituted — `Decimal.one` for a quantity that
/// must never be zero, `Decimal.zero` otherwise.
LineItemColumn<R> decimalColumn<R>({
  required String label,
  required Decimal? Function(R row) get,
  required R Function(R row, Decimal value) set,
  required void Function(BuildContext cellCtx, int index, R updatedRow)
  onChanged,
  Decimal? fallback,
  bool enabled = true,
  int flex = 1,
}) {
  return LineItemColumn<R>(
    label: label,
    flex: flex,
    cellBuilder: (cellCtx, row, index) => AppDecimalField(
      label: label,
      hideLabel: true,
      isBorderless: true,
      value: get(row),
      enabled: enabled,
      onChanged: (v) =>
          onChanged(cellCtx, index, set(row, v ?? fallback ?? Decimal.zero)),
    ),
  );
}

/// A read-only, right-aligned money column with tabular figures — the computed
/// line amount. [amount] derives the value from the row (callers keep any
/// "row is complete" guard inside that closure). Rendered as plain text, never
/// a disabled field: it carries no border or fill the user might mistake for an
/// input they failed to fill in.
LineItemColumn<R> moneyColumn<R>({
  required String label,
  required Decimal Function(R row) amount,
  int flex = 1,
}) {
  return LineItemColumn<R>(
    label: label,
    flex: flex,
    cellBuilder: (cellCtx, row, index) => Padding(
      padding: EdgeInsets.symmetric(vertical: cellCtx.tokens.spacing.sm),
      child: Text(
        amount(row).toMoney(symbol: ''),
        textAlign: TextAlign.end,
        style: Theme.of(cellCtx).textTheme.bodyMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}
