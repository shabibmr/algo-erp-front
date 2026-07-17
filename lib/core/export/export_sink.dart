/// The one place bytes leave the app.
///
/// Off the web they land in a real file and the path comes back; on the web the
/// browser takes the blob and never says where it put it, so the path is null.
/// Every exporter — Excel, CSV, anything later — goes through here rather than
/// growing its own platform fork.
library;

export 'export_sink_io.dart' if (dart.library.html) 'export_sink_web.dart';

/// MIME types for the formats we export.
abstract final class ExportMime {
  static const xlsx =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const csv = 'text/csv';
}
