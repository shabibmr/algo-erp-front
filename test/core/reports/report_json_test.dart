import 'package:algo_erp_front/core/reports/report_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('readJsonPath', () {
    test('reads nested keys', () {
      final row = {
        'sales_invoice_main': {'Total': 12.5, 'Vat_Amount': 1},
      };
      expect(readJsonPath(row, 'sales_invoice_main.Total'), 12.5);
      expect(readJsonPath(row, 'sales_invoice_main.Vat_Amount'), 1);
      expect(readJsonPath(row, 'missing'), isNull);
    });
  });

  group('extractReportRows', () {
    test('uses rowsPath for items', () {
      final data = {
        'items': [
          {'voucher_no': 'A1'},
          {'voucher_no': 'A2'},
        ],
        'meta': {'total': 2},
      };
      final rows = extractReportRows(data: data, rowsPath: 'items');
      expect(rows, hasLength(2));
      expect(rows.first['voucher_no'], 'A1');
    });

    test('treats list data as rows', () {
      final rows = extractReportRows(
        data: [
          {'a': 1},
          {'a': 2},
        ],
        rowsPath: null,
      );
      expect(rows, hasLength(2));
    });
  });

  group('formatReportCell', () {
    test('formats numbers and nulls', () {
      expect(formatReportCell(null), '');
      expect(formatReportCell(3), '3');
      expect(formatReportCell(1.5), '1.50');
      expect(formatReportCell(true), 'Yes');
    });
  });
}
