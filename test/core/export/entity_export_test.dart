import 'package:algo_erp_front/core/export/entity_export.dart';
import 'package:algo_erp_front/core/export/export_cell.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for any entity: the columns under test just read this back.
class _Row {
  const _Row(this.value);
  final String value;
}

FieldSpec<_Row> _column(
  FieldType type, {
  Object? Function(_Row)? exportValue,
}) => FieldSpec<_Row>(
  key: 'value',
  label: 'Value',
  type: type,
  cellValue: (r) => r.value,
  exportValue: exportValue,
);

ExportCell _cell(FieldType type, String display) =>
    EntityExport.cell(_column(type), _Row(display));

void main() {
  group('EntityExport.cell', () {
    test('the em-dash placeholder becomes blank, not literal text', () {
      // Manifests render a missing value as '—'. Exported literally it would
      // poison a SUM over the column.
      expect(_cell(FieldType.decimal, '—'), isA<BlankCell>());
      expect(_cell(FieldType.text, '—'), isA<BlankCell>());
      expect(_cell(FieldType.text, ''), isA<BlankCell>());
    });

    test('a money string is recovered as a number', () {
      // This is how DecimalFormatX.toMoney() renders — the display string the
      // list column actually hands us.
      final cell = _cell(FieldType.decimal, 'AED 1,234.50');
      expect(cell, isA<NumberCell>());
      expect((cell as NumberCell).value, 1234.5);
    });

    test('a plain grouped quantity is recovered as a number', () {
      final cell = _cell(FieldType.decimal, '1,234.5');
      expect((cell as NumberCell).value, 1234.5);
    });

    test('an accounting negative is recovered as negative', () {
      final cell = _cell(FieldType.decimal, '(1,234.50)');
      expect((cell as NumberCell).value, -1234.5);
    });

    test('an int column is recovered as a number', () {
      expect((_cell(FieldType.int, '42') as NumberCell).value, 42);
      expect((_cell(FieldType.int, '-7') as NumberCell).value, -7);
    });

    test('a numeric column that is not a number stays text', () {
      // Never guess. A wrong number in an accounts export is far worse than a
      // right value that happens to be formatted as text.
      final cell = _cell(FieldType.decimal, 'Not applicable');
      expect(cell, isA<TextCell>());
      expect((cell as TextCell).value, 'Not applicable');
    });

    test('a dd/MM/yyyy date is recovered as a date', () {
      final cell = _cell(FieldType.dateTime, '15/07/2026');
      expect(cell, isA<DateCell>());
      expect((cell as DateCell).value, DateTime(2026, 7, 15));
    });

    test('day-first parsing is not confused for month-first', () {
      // 07/11/2026 is 7 November, not 11 July. Getting this backwards silently
      // shifts a third of all exported dates.
      final cell = _cell(FieldType.dateTime, '07/11/2026') as DateCell;
      expect(cell.value.month, 11);
      expect(cell.value.day, 7);
    });

    test('a date with a time is recovered', () {
      final cell = _cell(FieldType.dateTime, '15/07/2026 14:05') as DateCell;
      expect(cell.value, DateTime(2026, 7, 15, 14, 5));
    });

    test('an ISO timestamp is recovered as a date', () {
      final cell = _cell(FieldType.dateTime, '2026-07-15T09:30:00') as DateCell;
      expect(cell.value.year, 2026);
      expect(cell.value.month, 7);
      expect(cell.value.day, 15);
    });

    test('an unparseable date stays text', () {
      expect(_cell(FieldType.dateTime, 'Never'), isA<TextCell>());
    });

    test('Yes/No is recovered as a bool', () {
      expect((_cell(FieldType.bool, 'Yes') as BoolCell).value, isTrue);
      expect((_cell(FieldType.bool, 'No') as BoolCell).value, isFalse);
    });

    test('fk and text columns pass through as text', () {
      expect((_cell(FieldType.fk, 'Cash A/C') as TextCell).value, 'Cash A/C');
      expect((_cell(FieldType.text, 'Cash') as TextCell).value, 'Cash');
    });

    test('exportValue overrides the parsed cellValue', () {
      // The escape hatch: a display string that cannot be read back.
      final column = _column(FieldType.decimal, exportValue: (_) => 99.5);
      final cell = EntityExport.cell(column, const _Row('about a hundred'));
      expect((cell as NumberCell).value, 99.5);
    });

    test('exportValue returning null blanks the cell', () {
      final column = _column(FieldType.text, exportValue: (_) => null);
      expect(EntityExport.cell(column, const _Row('x')), isA<BlankCell>());
    });
  });

  group('EntityExport.headers', () {
    test('are the column labels, in order', () {
      expect(
        EntityExport.headers([_column(FieldType.text), _column(FieldType.int)]),
        ['Value', 'Value'],
      );
    });
  });
}
