import 'dart:convert';

import 'package:algo_erp_front/core/export/excel_writer.dart';
import 'package:algo_erp_front/core/export/export_cell.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads the parts back out of the workbook the way Excel would.
Map<String, String> _unzip(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  return {
    for (final file in archive.files)
      if (file.isFile) file.name: utf8.decode(file.readBytes()!),
  };
}

void main() {
  group('ExcelWriter.build', () {
    test('emits every part Excel requires to open the file', () {
      final parts = _unzip(
        ExcelWriter.build(
          sheetName: 'Ledgers',
          headers: const ['Name'],
          rows: const [
            [TextCell('Cash')],
          ],
        ),
      );

      expect(
        parts.keys,
        containsAll([
          '[Content_Types].xml',
          '_rels/.rels',
          'xl/workbook.xml',
          'xl/_rels/workbook.xml.rels',
          'xl/styles.xml',
          'xl/worksheets/sheet1.xml',
        ]),
      );
    });

    test('every part is well-formed XML', () {
      final parts = _unzip(
        ExcelWriter.build(
          sheetName: 'Ledgers',
          headers: const ['Name', 'Total'],
          rows: const [
            [TextCell('Cash & Bank <main>'), NumberCell(12.5)],
          ],
        ),
      );

      // A single malformed part makes the whole workbook unopenable, and the
      // failure Excel shows is famously unhelpful, so parse them all here.
      for (final entry in parts.entries) {
        expect(
          () => _XmlWellFormed.parse(entry.value),
          returnsNormally,
          reason: '${entry.key} is not well-formed',
        );
      }
    });

    test('a number lands as a number, not as text', () {
      final sheet = _unzip(
        ExcelWriter.build(
          sheetName: 'S',
          headers: const ['Total'],
          rows: const [
            [NumberCell(1234.5)],
          ],
        ),
      )['xl/worksheets/sheet1.xml']!;

      // No t="inlineStr" on the cell, and the raw value in <v>. This is the
      // whole reason the export is not a CSV: SUM() over the column has to
      // work.
      expect(sheet, contains('<c r="A2"><v>1234.5</v></c>'));
      expect(sheet, isNot(contains('<c r="A2" t="inlineStr"')));
    });

    test('a whole number does not pick up a trailing .0', () {
      final sheet = _unzip(
        ExcelWriter.build(
          sheetName: 'S',
          headers: const ['Qty'],
          rows: const [
            [NumberCell(7)],
          ],
        ),
      )['xl/worksheets/sheet1.xml']!;

      expect(sheet, contains('<v>7</v>'));
    });

    test('a date lands as an Excel serial under the date style', () {
      final sheet = _unzip(
        ExcelWriter.build(
          sheetName: 'S',
          headers: const ['Date'],
          rows: [
            [DateCell(DateTime(2026, 7, 15))],
          ],
        ),
      )['xl/worksheets/sheet1.xml']!;

      // 2026-07-15 is 46218 days after Excel's 1899-12-30 epoch. If this drifts
      // by one, the epoch is wrong (the 1900 leap-year bug) — a silent
      // off-by-one-day on every exported date.
      expect(sheet, contains('<c r="A2" s="2"><v>46218</v></c>'));
    });

    test('a bool lands as a bool', () {
      final sheet = _unzip(
        ExcelWriter.build(
          sheetName: 'S',
          headers: const ['Active'],
          rows: const [
            [BoolCell(true)],
            [BoolCell(false)],
          ],
        ),
      )['xl/worksheets/sheet1.xml']!;

      expect(sheet, contains('<c r="A2" t="b"><v>1</v></c>'));
      expect(sheet, contains('<c r="A3" t="b"><v>0</v></c>'));
    });

    test('the header row is bold and frozen', () {
      final sheet = _unzip(
        ExcelWriter.build(
          sheetName: 'S',
          headers: const ['Name'],
          rows: const [],
        ),
      )['xl/worksheets/sheet1.xml']!;

      expect(sheet, contains('s="1"')); // the bold style
      expect(sheet, contains('state="frozen"'));
    });

    test('XML metacharacters in a value are escaped, not emitted raw', () {
      final sheet = _unzip(
        ExcelWriter.build(
          sheetName: 'S',
          headers: const ['Name'],
          rows: const [
            [TextCell('R&D <tools> "x"')],
          ],
        ),
      )['xl/worksheets/sheet1.xml']!;

      expect(sheet, contains('R&amp;D &lt;tools&gt; &quot;x&quot;'));
    });

    test('control characters are dropped rather than corrupting the file', () {
      // XML 1.0 cannot represent these at all — not even escaped. A single one
      // reaching the file makes the workbook unopenable.
      final bytes = ExcelWriter.build(
        sheetName: 'S',
        headers: const ['Name'],
        rows: [
          [TextCell('bad${String.fromCharCode(0x07)}value')],
        ],
      );

      final sheet = _unzip(bytes)['xl/worksheets/sheet1.xml']!;
      expect(sheet, contains('badvalue'));
      expect(() => _XmlWellFormed.parse(sheet), returnsNormally);
    });

    test('columns past Z are addressed correctly', () {
      final headers = [for (var i = 0; i < 28; i++) 'C$i'];
      final sheet = _unzip(
        ExcelWriter.build(
          sheetName: 'S',
          headers: headers,
          rows: [
            [for (var i = 0; i < 28; i++) const TextCell('x')],
          ],
        ),
      )['xl/worksheets/sheet1.xml']!;

      // 27th and 28th columns are AA and AB — a naive A..Z scheme silently
      // wraps here and Excel rejects the row.
      expect(sheet, contains('r="AA2"'));
      expect(sheet, contains('r="AB2"'));
    });

    test('a sheet name Excel would reject is sanitised', () {
      final workbook = _unzip(
        ExcelWriter.build(
          sheetName: 'Profit/Loss [2026]: a very long statement name indeed',
          headers: const ['A'],
          rows: const [],
        ),
      )['xl/workbook.xml']!;

      // Assert on the sheet name itself — the document is full of legitimate
      // slashes, in the namespace URIs.
      final name = RegExp(
        '<sheet name="([^"]*)"',
      ).firstMatch(workbook)!.group(1)!;
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('[')));
      expect(name, isNot(contains(':')));
      // 31 chars is Excel's hard limit on a sheet name.
      expect(name.length, lessThanOrEqualTo(31));
    });

    test('an export with no rows still produces a valid workbook', () {
      final parts = _unzip(
        ExcelWriter.build(
          sheetName: 'S',
          headers: const ['Name'],
          rows: const [],
        ),
      );
      expect(
        () => _XmlWellFormed.parse(parts['xl/worksheets/sheet1.xml']!),
        returnsNormally,
      );
    });
  });
}

/// A deliberately strict, dependency-free XML well-formedness check.
///
/// `package:xml` is present transitively (via `pdf`) but is not a declared
/// dependency of this project, and the point here is only to prove the bytes
/// parse: tags balance, attributes are quoted, no raw `&` or `<` in text.
abstract final class _XmlWellFormed {
  static void parse(String xml) {
    final stack = <String>[];
    final tag = RegExp(r'<(/?)([A-Za-z_][\w:.-]*)([^>]*?)(/?)>');

    var cursor = 0;
    for (final match in tag.allMatches(xml)) {
      _checkText(xml.substring(cursor, match.start));
      cursor = match.end;

      final closing = match.group(1) == '/';
      final name = match.group(2)!;
      final attrs = match.group(3)!;
      final selfClosing = match.group(4) == '/';

      _checkAttributes(attrs, name);

      if (closing) {
        if (stack.isEmpty || stack.removeLast() != name) {
          throw FormatException('unbalanced </$name>');
        }
      } else if (!selfClosing) {
        stack.add(name);
      }
    }
    _checkText(xml.substring(cursor));

    if (stack.isNotEmpty) throw FormatException('unclosed <${stack.last}>');
  }

  static void _checkText(String text) {
    // Strip the XML/processing declaration, which is not an element.
    final body = text.replaceAll(RegExp(r'<\?.*?\?>'), '');
    if (body.contains('<')) throw const FormatException('raw < in text');
    if (RegExp(r'&(?!(amp|lt|gt|quot|apos|#\d+);)').hasMatch(body)) {
      throw const FormatException('unescaped & in text');
    }
    for (final rune in body.runes) {
      if (rune < 0x20 && rune != 0x09 && rune != 0x0A && rune != 0x0D) {
        throw FormatException('control character U+${rune.toRadixString(16)}');
      }
    }
  }

  static void _checkAttributes(String attrs, String tag) {
    final trimmed = attrs.trim();
    if (trimmed.isEmpty) return;
    final attr = RegExp(r'''([\w:.-]+)\s*=\s*"([^"]*)"''');
    final consumed = attr
        .allMatches(trimmed)
        .fold(0, (sum, m) => sum + m.group(0)!.length);
    // Everything that is not an attribute must be the whitespace between them.
    final leftover = trimmed.length - consumed;
    final gaps = RegExp(r'\s+').allMatches(trimmed).length;
    if (leftover > gaps + 1) {
      throw FormatException('malformed attributes on <$tag>: $trimmed');
    }
  }
}
