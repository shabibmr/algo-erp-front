// dart:html is deprecated in favour of package:web, but this file is only ever
// compiled for web (see the conditional import in export_sink.dart) and the
// swap is a separate migration.
//
// avoid_web_libraries_in_flutter fires on `dart:html` in a non-plugin — which
// is the point of the conditional import: this file is the web half of it.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

/// Hands the bytes to the browser as a download.
///
/// [mimeType] matters here and only here: the browser decides what to do with
/// the blob by its type, so an `.xlsx` handed over as `text/csv` opens as text.
///
/// Returns null: the file goes wherever the browser puts downloads, and the
/// page never learns the path.
Future<String?> saveExportBytes(
  List<int> bytes,
  String filename,
  String mimeType,
) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return null;
}
