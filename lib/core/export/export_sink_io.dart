import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Writes an export to disk and returns the path it landed at.
///
/// Desktop gets the real Downloads folder. Android and iOS have no such thing
/// exposed to an app, so they get the app's documents directory — the caller
/// shows the returned path, because a file the user cannot find is no better
/// than no file at all.
///
/// [mimeType] is ignored off the web: the extension carries the format here.
Future<String?> saveExportBytes(
  List<int> bytes,
  String filename,
  String mimeType,
) async {
  Directory? dir;
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    dir = await getDownloadsDirectory();
  }
  dir ??= await getApplicationDocumentsDirectory();

  final file = File(await _freePath(dir, filename));
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

/// Never overwrite an earlier export: every master exports to a fixed filename,
/// so a second export would silently replace the first one the user still had
/// open. Suffix instead — `foo.xlsx`, `foo (1).xlsx`, `foo (2).xlsx`.
Future<String> _freePath(Directory dir, String filename) async {
  final ext = p.extension(filename);
  final stem = p.basenameWithoutExtension(filename);

  var candidate = p.join(dir.path, filename);
  var n = 1;
  while (File(candidate).existsSync()) {
    candidate = p.join(dir.path, '$stem ($n)$ext');
    n++;
  }
  return candidate;
}
