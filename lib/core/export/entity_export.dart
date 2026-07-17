import 'package:algo_erp_front/core/export/export_cell.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';

/// Turns a manifest's list columns into spreadsheet cells.
///
/// A list surface only ever asked its columns for a display string, so that is
/// all `FieldSpec.cellValue` returns. An export wants the *value* back: a total
/// the user can sum, a date they can sort on. `FieldSpec.type` already says
/// what the column is, so we use it to read the display string back into a
/// typed cell — which means every one of the 34 existing manifests gains a
/// correctly-typed export without being touched.
///
/// Where a display string is genuinely lossy, the manifest sets
/// `FieldSpec.exportValue` and that wins outright. Parsing never guesses: a
/// string that does not cleanly read back stays text, because a wrong number in
/// an accounts export is far worse than a right one formatted as text.
abstract final class EntityExport {
  static List<String> headers<E>(List<FieldSpec<E>> columns) => [
    for (final column in columns) column.label,
  ];

  static List<List<ExportCell>> rows<E>(
    List<FieldSpec<E>> columns,
    List<E> items,
  ) => [for (final item in items) row(columns, item)];

  static List<ExportCell> row<E>(List<FieldSpec<E>> columns, E item) => [
    for (final column in columns) cell(column, item),
  ];

  static ExportCell cell<E>(FieldSpec<E> column, E item) {
    final override = column.exportValue;
    if (override != null) return ExportCell.of(override(item));

    final raw = column.cellValue(item).trim();
    if (_isBlank(raw)) return const BlankCell();

    return switch (column.type) {
      FieldType.int || FieldType.decimal => _number(raw) ?? TextCell(raw),
      FieldType.dateTime => _date(raw) ?? TextCell(raw),
      FieldType.bool => _bool(raw) ?? TextCell(raw),
      FieldType.text || FieldType.fk || FieldType.selfFk => TextCell(raw),
    };
  }

  /// Manifests render a missing value as an em-dash. Exporting that literally
  /// would put `—` in a numeric column, which Excel reads as text and which
  /// poisons a SUM over the range.
  static bool _isBlank(String raw) =>
      raw.isEmpty || raw == '—' || raw == '-' || raw == 'N/A';

  /// Reads `1,234.50`, `AED 1,234.50`, `(1,234.50)` and `-1234.5` back to a
  /// number. Anything with letters left over after the symbols are stripped is
  /// not a number we are willing to guess at.
  static NumberCell? _number(String raw) {
    var s = raw.replaceAll(',', '').replaceAll(RegExp(r'\s'), '');

    // Accounting negatives: (1234.50) means -1234.50.
    var negative = false;
    if (s.startsWith('(') && s.endsWith(')')) {
      negative = true;
      s = s.substring(1, s.length - 1);
    }

    // Strip a leading currency symbol or code (AED, $, %) — but only symbols.
    final match = _numeric.firstMatch(s);
    if (match == null) return null;

    final value = double.tryParse(match.group(1)!);
    if (value == null) return null;
    return NumberCell(negative ? -value : value);
  }

  /// The manifests format dates through `DateTimeFormatX` — `dd/MM/yyyy`, or
  /// `dd/MM/yyyy HH:mm` with a time. ISO is accepted too, for the columns that
  /// pass a wire value straight through.
  static DateCell? _date(String raw) {
    final match = _dayFirst.firstMatch(raw);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final hour = int.tryParse(match.group(4) ?? '') ?? 0;
      final minute = int.tryParse(match.group(5) ?? '') ?? 0;
      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      return DateCell(DateTime(year, month, day, hour, minute));
    }

    final iso = DateTime.tryParse(raw);
    return iso == null ? null : DateCell(iso);
  }

  static BoolCell? _bool(String raw) => switch (raw.toLowerCase()) {
    'yes' || 'true' || 'active' || '1' => const BoolCell(true),
    'no' || 'false' || 'inactive' || '0' => const BoolCell(false),
    _ => null,
  };

  /// A number, optionally wrapped in non-alphanumeric symbols. `AED` is letters
  /// and so would fail this — which is why the currency prefix is stripped by
  /// the alternation on the left rather than by a catch-all.
  static final _numeric = RegExp(
    r'^(?:[A-Za-z]{1,3}\.?)?[^\d\-+.]*([-+]?\d*\.?\d+)[^\dA-Za-z]*$',
  );

  static final _dayFirst = RegExp(
    r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:\s+(\d{1,2}):(\d{2}))?$',
  );

  /// A cell for a value straight out of a report's JSON.
  ///
  /// Reports have no `FieldSpec` to say what a column is, but the payload is
  /// decoded JSON, so most values already carry their type — a `num` is a
  /// number, a `bool` is a bool. The one thing JSON cannot express is a date:
  /// it arrives as an ISO string, and left alone it would land in the
  /// spreadsheet as text no user could sort on.
  static ExportCell reportCell(Object? value) {
    if (value is String && _iso.hasMatch(value)) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return DateCell(parsed);
    }
    return ExportCell.of(value);
  }

  static final _iso = RegExp(r'^\d{4}-\d{2}-\d{2}');
}
