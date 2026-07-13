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
