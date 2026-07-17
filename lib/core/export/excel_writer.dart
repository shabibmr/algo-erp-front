// The OOXML parts below are split across adjacent string literals purely to
// keep lines under 80 chars. `missing_whitespace_between_adjacent_strings`
// assumes it is looking at prose, but these are namespace URIs and MIME types:
// inserting the whitespace it asks for would corrupt every one of them.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:algo_erp_front/core/export/export_cell.dart';
import 'package:algo_erp_front/core/export/export_sink.dart';
import 'package:archive/archive.dart';

/// Writes a real `.xlsx` workbook — not a CSV wearing a spreadsheet's name.
///
/// **Why hand-rolled.** `package:excel` is the obvious choice and was tried
/// first: every published version pins `xml <7.0.0`, while `package:pdf` (the
/// print stack) requires `xml ^7`, so the two cannot coexist. Downgrading the
/// PDF engine to gain a spreadsheet writer is a bad trade, and the commercial
/// kits are out of bounds (see the stack boundary in `docs/BUILD_TASKS_V2.md`).
///
/// An `.xlsx` is a zip of XML parts, so that is what this builds. We emit the
/// minimum OOXML that Excel, LibreOffice and Google Sheets all accept:
///
/// ```text
/// [Content_Types].xml      what each part is
/// _rels/.rels              root → workbook
/// xl/workbook.xml          one sheet
/// xl/_rels/workbook.xml.rels
/// xl/styles.xml            three styles: default, bold header, date
/// xl/worksheets/sheet1.xml the cells
/// ```
///
/// Strings are written inline rather than through a shared-strings table: it
/// costs a few bytes on repetitive columns and saves a whole part plus a
/// dictionary pass.
abstract final class ExcelWriter {
  /// Builds the workbook and hands the bytes to the sink.
  ///
  /// Returns the path it was written to, or null on web, where the browser owns
  /// the download and never tells us where it went.
  static Future<String?> write({
    required String filename,
    required String sheetName,
    required List<String> headers,
    required List<List<ExportCell>> rows,
  }) async {
    final bytes = build(sheetName: sheetName, headers: headers, rows: rows);
    return saveExportBytes(bytes, filename, ExportMime.xlsx);
  }

  /// The workbook as bytes. Split out from [write] so it can be tested without
  /// touching a filesystem.
  static List<int> build({
    required String sheetName,
    required List<String> headers,
    required List<List<ExportCell>> rows,
  }) {
    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypes))
      ..addFile(ArchiveFile.string('_rels/.rels', _rootRels))
      ..addFile(ArchiveFile.string('xl/workbook.xml', _workbook(sheetName)))
      ..addFile(ArchiveFile.string('xl/_rels/workbook.xml.rels', _workbookRels))
      ..addFile(ArchiveFile.string('xl/styles.xml', _styles))
      ..addFile(
        ArchiveFile.string(
          'xl/worksheets/sheet1.xml',
          _sheet(headers: headers, rows: rows),
        ),
      );

    return ZipEncoder().encodeBytes(archive);
  }

  // ---------------------------------------------------------------- the sheet

  static String _sheet({
    required List<String> headers,
    required List<List<ExportCell>> rows,
  }) {
    final b = StringBuffer()
      ..write(_xmlDecl)
      ..write(
        '<worksheet xmlns="$_nsMain" '
        'xmlns:r="$_nsRel">',
      )
      // Freeze the header so it stays put on a long export.
      ..write(
        '<sheetViews><sheetView workbookViewId="0">'
        '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" '
        'state="frozen"/>'
        '</sheetView></sheetViews>',
      )
      ..write(_cols(headers: headers, rows: rows))
      ..write('<sheetData>')
      ..write(
        _row(
          index: 1,
          cells: [for (final h in headers) TextCell(h)],
          style: _styleHeader,
        ),
      );

    for (var i = 0; i < rows.length; i++) {
      b.write(_row(index: i + 2, cells: rows[i]));
    }

    b.write('</sheetData></worksheet>');
    return b.toString();
  }

  static String _row({
    required int index,
    required List<ExportCell> cells,
    int? style,
  }) {
    final b = StringBuffer('<row r="$index">');
    for (var c = 0; c < cells.length; c++) {
      b.write(
        _cell(ref: '${_columnName(c)}$index', cell: cells[c], style: style),
      );
    }
    b.write('</row>');
    return b.toString();
  }

  static String _cell({
    required String ref,
    required ExportCell cell,
    int? style,
  }) {
    // A style of 0 is the default and can be left off entirely.
    String attr(int s) => s == _styleDefault ? '' : ' s="$s"';

    return switch (cell) {
      BlankCell() when style == null => '',
      BlankCell() => '<c r="$ref"${attr(style!)}/>',
      TextCell(:final value) =>
        '<c r="$ref"${attr(style ?? _styleDefault)} t="inlineStr">'
            '<is><t xml:space="preserve">${_esc(value)}</t></is></c>',
      NumberCell(:final value) =>
        '<c r="$ref"${attr(style ?? _styleDefault)}>'
            '<v>${_num(value)}</v></c>',
      DateCell(:final value) =>
        '<c r="$ref"${attr(style ?? _styleDate)}>'
            '<v>${_num(_serial(value))}</v></c>',
      BoolCell(:final value) =>
        '<c r="$ref"${attr(style ?? _styleDefault)} t="b">'
            '<v>${value ? 1 : 0}</v></c>',
    };
  }

  /// Widths sized to the content, so an export doesn't open as a wall of `####`
  /// on the money columns. Sampled, not exhaustive: a 5000-row export does not
  /// need to measure all 5000 to know how wide the column should be.
  static String _cols({
    required List<String> headers,
    required List<List<ExportCell>> rows,
  }) {
    if (headers.isEmpty) return '';

    final widths = [for (final h in headers) h.length];
    final sample = rows.length > _widthSample ? rows.take(_widthSample) : rows;
    for (final row in sample) {
      for (var c = 0; c < row.length && c < widths.length; c++) {
        final len = _displayLength(row[c]);
        if (len > widths[c]) widths[c] = len;
      }
    }

    final b = StringBuffer('<cols>');
    for (var c = 0; c < widths.length; c++) {
      final w = (widths[c] + 2).clamp(_minWidth, _maxWidth);
      b.write(
        '<col min="${c + 1}" max="${c + 1}" width="$w" '
        'customWidth="1"/>',
      );
    }
    b.write('</cols>');
    return b.toString();
  }

  static int _displayLength(ExportCell cell) => switch (cell) {
    BlankCell() => 0,
    TextCell(:final value) => value.length,
    NumberCell(:final value) => _num(value).length,
    DateCell() => 10, // dd/mm/yyyy
    BoolCell() => 5,
  };

  // ------------------------------------------------------------------ helpers

  /// Excel counts days from 1899-12-30 (the leap-year bug it inherited from
  /// Lotus is why it is not the 31st). Computed in UTC so a timezone with DST
  /// cannot shift a date by a day.
  static double _serial(DateTime date) {
    final utc = DateTime.utc(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
    );
    return utc.difference(_excelEpoch).inMicroseconds /
        Duration.microsecondsPerDay;
  }

  /// Numbers go into the file in invariant form — no thousands separators, no
  /// exponent for values a spreadsheet would rather see in full, and no
  /// trailing `.0` on whole numbers.
  static String _num(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }

  /// `A`, `B`, … `Z`, `AA`, `AB`, … for a zero-based column index.
  static String _columnName(int index) {
    var n = index;
    final b = StringBuffer();
    while (true) {
      b.write(String.fromCharCode(65 + n % 26));
      n = n ~/ 26 - 1;
      if (n < 0) break;
    }
    return String.fromCharCodes(b.toString().codeUnits.reversed);
  }

  /// XML 1.0 forbids most control characters outright — they cannot be escaped,
  /// only dropped, and a single stray one makes the whole workbook unopenable.
  static String _esc(String value) {
    final b = StringBuffer();
    for (final rune in value.runes) {
      switch (rune) {
        case 0x26:
          b.write('&amp;');
        case 0x3C:
          b.write('&lt;');
        case 0x3E:
          b.write('&gt;');
        case 0x22:
          b.write('&quot;');
        case 0x27:
          b.write('&apos;');
        case 0x09:
        case 0x0A:
        case 0x0D:
          b.writeCharCode(rune);
        default:
          if (rune >= 0x20) b.writeCharCode(rune);
      }
    }
    return b.toString();
  }

  // -------------------------------------------------------- the static parts

  static final DateTime _excelEpoch = DateTime.utc(1899, 12, 30);

  static const _widthSample = 200;
  static const _minWidth = 8;
  static const _maxWidth = 60;

  static const _styleDefault = 0;
  static const _styleHeader = 1;
  static const _styleDate = 2;

  static const _nsMain =
      'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  static const _nsRel =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  static const _xmlDecl =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';

  static const _contentTypes =
      '$_xmlDecl'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/'
      'content-types">'
      '<Default Extension="rels" ContentType="application/'
      'vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/'
      'vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/'
      'vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/'
      'vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '</Types>';

  static const _rootRels =
      '$_xmlDecl'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/'
      'relationships">'
      '<Relationship Id="rId1" Type="$_nsRel/officeDocument" '
      'Target="xl/workbook.xml"/>'
      '</Relationships>';

  static const _workbookRels =
      '$_xmlDecl'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/'
      'relationships">'
      '<Relationship Id="rId1" Type="$_nsRel/worksheet" '
      'Target="worksheets/sheet1.xml"/>'
      '<Relationship Id="rId2" Type="$_nsRel/styles" Target="styles.xml"/>'
      '</Relationships>';

  /// numFmt 164 is the first id available to a document; the built-ins below it
  /// are fixed by the spec and none of them is `dd/mm/yyyy`.
  static const _styles =
      '$_xmlDecl'
      '<styleSheet xmlns="$_nsMain">'
      '<numFmts count="1">'
      '<numFmt numFmtId="164" formatCode="dd/mm/yyyy"/>'
      '</numFmts>'
      '<fonts count="2">'
      '<font><sz val="11"/><name val="Calibri"/></font>'
      '<font><b/><sz val="11"/><name val="Calibri"/></font>'
      '</fonts>'
      '<fills count="2">'
      '<fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="gray125"/></fill>'
      '</fills>'
      '<borders count="1"><border/></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" '
      'borderId="0"/></cellStyleXfs>'
      '<cellXfs count="3">'
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" '
      'applyFont="1"/>'
      '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" '
      'applyNumberFormat="1"/>'
      '</cellXfs>'
      '</styleSheet>';

  static String _workbook(String sheetName) =>
      '$_xmlDecl'
      '<workbook xmlns="$_nsMain" xmlns:r="$_nsRel">'
      '<sheets>'
      '<sheet name="${_esc(_safeSheetName(sheetName))}" sheetId="1" '
      'r:id="rId1"/>'
      '</sheets>'
      '</workbook>';

  /// Excel rejects a sheet name over 31 characters or containing any of
  /// `[ ] : * ? / \` — a silent corruption if we pass an entity label straight
  /// through.
  static String _safeSheetName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').trim();
    if (cleaned.isEmpty) return 'Sheet1';
    return cleaned.length <= 31 ? cleaned : cleaned.substring(0, 31);
  }
}
