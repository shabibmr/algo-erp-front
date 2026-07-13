// dart:html is deprecated in favour of package:web, but this file is only ever
// compiled for web (see the conditional import in csv_exporter.dart) and the
// swap is a separate migration.
// ignore_for_file: deprecated_member_use

import 'dart:html' as html;

/// Hands the bytes to the browser as a download.
///
/// Returns null: the file goes wherever the browser puts downloads, and the
/// page never learns the path.
Future<String?> saveCsvBytes(List<int> bytes, String filename) async {
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return null;
}
