// dart:html is the established pattern for blob download
// (see csv_exporter_web).
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Opens a blob URL in a new tab so the browser can print server HTML.
void openSalesInvoiceHtml(String htmlContent) {
  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // Revoke after the new tab has a chance to load.
  Future<void>.delayed(const Duration(seconds: 30), () {
    html.Url.revokeObjectUrl(url);
  });
}
