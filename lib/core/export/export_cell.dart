import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

/// One cell of an export, carrying its *type* rather than its rendering.
///
/// This is the whole point of exporting to a spreadsheet instead of to text: a
/// number written as a number can be summed, a date written as a date can be
/// sorted and filtered. A screen only ever needs the display string, so the
/// list surfaces hand us those — [ExportCell] is where we recover the type the
/// screen threw away.
@immutable
sealed class ExportCell {
  const ExportCell();

  /// Chooses the narrowest cell that fits [value]. Anything we can't type
  /// confidently falls back to text, which is always safe.
  factory ExportCell.of(Object? value) {
    if (value == null) return const BlankCell();
    if (value is ExportCell) return value;
    if (value is bool) return BoolCell(value);
    if (value is num) return NumberCell(value.toDouble());
    if (value is Decimal) return NumberCell(value.toDouble());
    if (value is DateTime) return DateCell(value);
    final text = value.toString();
    return text.isEmpty ? const BlankCell() : TextCell(text);
  }
}

/// An empty cell. Distinct from `TextCell('')` so that a manifest's `'—'`
/// null-placeholder does not land in the spreadsheet as a literal em-dash.
final class BlankCell extends ExportCell {
  const BlankCell();
}

final class TextCell extends ExportCell {
  const TextCell(this.value);
  final String value;
}

final class NumberCell extends ExportCell {
  const NumberCell(this.value);
  final double value;
}

final class DateCell extends ExportCell {
  const DateCell(this.value);
  final DateTime value;
}

final class BoolCell extends ExportCell {
  // A cell *is* its value; naming the parameter would read as `BoolCell(value:
  // true)`, which says nothing the type didn't already.
  // ignore: avoid_positional_boolean_parameters
  const BoolCell(this.value);
  final bool value;
}
