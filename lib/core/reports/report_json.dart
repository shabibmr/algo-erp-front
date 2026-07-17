import 'package:algo_erp_front/core/reports/report_definition.dart';

/// Small JSON path helpers for report rows (dot-paths only).
Object? readJsonPath(Object? root, String path) {
  if (path.isEmpty) return root;
  var cur = root;
  for (final part in path.split('.')) {
    if (cur is Map<dynamic, dynamic>) {
      cur = cur[part];
    } else {
      return null;
    }
  }
  return cur;
}

String formatReportCell(Object? value) {
  if (value == null) return '';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is num) {
    if (value is int || value == value.roundToDouble()) {
      return value.toString();
    }
    return value.toStringAsFixed(2);
  }
  final s = value.toString();
  // ISO date → day only when pure date-ish.
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
    final d = DateTime.tryParse(s);
    if (d != null) {
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      return '$dd/$mm/${d.year}';
    }
  }
  return s;
}

List<Map<String, dynamic>> extractReportRows({
  required Object? data,
  required String? rowsPath,
}) {
  var target = data;
  if (rowsPath != null && rowsPath.isNotEmpty) {
    target = readJsonPath(data, rowsPath);
  }
  if (target is List) {
    return [
      for (final e in target)
        if (e is Map<dynamic, dynamic>) Map<String, dynamic>.from(e),
    ];
  }
  return const [];
}

/// A report flattened to one header row and a rectangular body.
typedef ReportTable = ({List<String> headers, List<List<Object?>> rows});

/// Flattens any report — whatever its [ReportShape] — into a single table.
///
/// **Values stay raw.** A number arrives here as a `num` and leaves as one, so
/// the Excel export can write it into a cell the user can sum. The consumers
/// that need text (CSV, PDF) run the cells through [formatReportCell]
/// themselves. This used to be inlined three times in `ReportViewer` — once per
/// destination — which is how CSV and PDF drifted apart on the sections shape.
ReportTable flattenReport(ReportDefinition def, Object? data) =>
    switch (def.shape) {
      ReportShape.sections => _flattenSections(
        data: data,
        sections: def.sections,
        totals: def.columns,
      ),
      ReportShape.summary => (
        headers: [for (final c in def.columns) c.label],
        rows: [
          [
            for (final c in def.columns)
              readJsonPath(
                data is Map<dynamic, dynamic>
                    ? Map<String, dynamic>.from(data)
                    : const <String, dynamic>{},
                c.key,
              ),
          ],
        ],
      ),
      ReportShape.table => (
        headers: [for (final c in def.columns) c.label],
        rows: [
          for (final row in extractReportRows(
            data: data,
            rowsPath: def.rowsPath,
          ))
            [for (final c in def.columns) readJsonPath(row, c.key)],
        ],
      ),
    };

/// A statement has several parallel row lists and a totals block, but an export
/// takes one header row: every line is tagged with its section, and the totals
/// are appended as trailing `Totals` rows.
ReportTable _flattenSections({
  required Object? data,
  required List<ReportSectionSpec> sections,
  required List<ReportColumnSpec> totals,
}) {
  final width = sections.fold<int>(
    0,
    (m, s) => s.columns.length > m ? s.columns.length : m,
  );
  if (width == 0) return (headers: const ['Section'], rows: const []);

  final labels = [
    for (final c in sections.first.columns) c.label,
    for (var i = sections.first.columns.length; i < width; i++) '',
  ];

  final rows = <List<Object?>>[];
  for (final section in sections) {
    for (final row in extractReportRows(
      data: data,
      rowsPath: section.rowsPath,
    )) {
      final cells = [for (final c in section.columns) readJsonPath(row, c.key)];
      rows.add([
        section.title,
        ...cells,
        for (var i = cells.length; i < width; i++) null,
      ]);
    }
  }

  final map = data is Map<dynamic, dynamic>
      ? Map<String, dynamic>.from(data)
      : const <String, dynamic>{};
  for (final c in totals) {
    final cells = List<Object?>.filled(width, null);
    cells[0] = c.label;
    if (width > 1) cells[1] = readJsonPath(map, c.key);
    rows.add(['Totals', ...cells]);
  }

  return (headers: ['Section', ...labels], rows: rows);
}
