import 'dart:convert';

import 'package:algo_erp_front/core/export/export_cell.dart';
import 'package:algo_erp_front/core/export/export_sink.dart';
import 'package:intl/intl.dart';

/// Writes a CSV — the secondary export format, kept for the tools that want a
/// plain text feed rather than a workbook. `ExcelWriter` is the primary path.
///
/// Separator stays `|`, as it has been, to comply with system-wide rules.
abstract final class CsvWriter {
  static const _separator = '|';

  static Future<String?> write({
    required String filename,
    required List<String> headers,
    required List<List<ExportCell>> rows,
  }) {
    final buffer = StringBuffer()
      ..writeln(headers.map(_escape).join(_separator));
    for (final row in rows) {
      buffer.writeln(row.map(_render).map(_escape).join(_separator));
    }
    return saveExportBytes(
      utf8.encode(buffer.toString()),
      filename,
      ExportMime.csv,
    );
  }

  /// The typed cell collapses back to text here — this is the format's whole
  /// limitation, and the reason Excel is the default.
  static String _render(ExportCell cell) => switch (cell) {
    BlankCell() => '',
    TextCell(:final value) => value,
    NumberCell(:final value) =>
      value == value.roundToDouble() && value.abs() < 1e15
          ? value.toStringAsFixed(0)
          : value.toString(),
    DateCell(:final value) => _date.format(value),
    BoolCell(:final value) => value ? 'Yes' : 'No',
  };

  static String _escape(String cell) {
    var escaped = cell.replaceAll('"', '""');
    if (escaped.contains(_separator) ||
        escaped.contains('\n') ||
        escaped.contains('"')) {
      escaped = '"$escaped"';
    }
    return escaped;
  }

  static final _date = DateFormat('dd/MM/yyyy');
}
