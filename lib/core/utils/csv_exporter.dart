import 'dart:convert';
import 'csv_exporter_stub.dart'
    if (dart.library.html) 'csv_exporter_web.dart';

class CsvExporter {
  /// Exports a list of items to a CSV file.
  /// Uses '|' as the separator to comply with system-wide rules.
  static void exportToCsv({
    required String filename,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final csvBuffer = StringBuffer();
    
    // Write headers separated by |
    csvBuffer.writeln(headers.join('|'));
    
    // Write rows separated by |
    for (final row in rows) {
      csvBuffer.writeln(row.map((cell) {
        var escaped = cell.replaceAll('"', '""');
        // If content contains pipes, newlines, or quotes, enclose in quotes
        if (escaped.contains('|') || escaped.contains('\n') || escaped.contains('"')) {
          escaped = '"$escaped"';
        }
        return escaped;
      }).join('|'));
    }

    final bytes = utf8.encode(csvBuffer.toString());
    saveCsvBytes(bytes, filename);
  }
}
