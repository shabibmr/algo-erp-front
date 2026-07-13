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

/// Flattens a [ReportShape.sections] payload into a single table for CSV and
/// PDF, which both take one header row: every row is tagged with its section,
/// and the totals block is appended as trailing `Totals` rows.
({List<String> headers, List<List<String>> rows}) flattenReportSections({
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

  final rows = <List<String>>[];
  for (final section in sections) {
    for (final row in extractReportRows(
      data: data,
      rowsPath: section.rowsPath,
    )) {
      final cells = [
        for (final c in section.columns)
          formatReportCell(readJsonPath(row, c.key)),
      ];
      rows.add([
        section.title,
        ...cells,
        for (var i = cells.length; i < width; i++) '',
      ]);
    }
  }

  final map = data is Map<dynamic, dynamic>
      ? Map<String, dynamic>.from(data)
      : const <String, dynamic>{};
  for (final c in totals) {
    final cells = List.filled(width, '');
    cells[0] = c.label;
    if (width > 1) cells[1] = formatReportCell(readJsonPath(map, c.key));
    rows.add(['Totals', ...cells]);
  }

  return (headers: ['Section', ...labels], rows: rows);
}
