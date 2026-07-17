import 'package:algo_erp_front/core/reports/report_catalog.dart';
import 'package:algo_erp_front/core/reports/report_json.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real `GET /transactions/reports/balance-sheet` envelope `data`.
const _balanceSheetData = {
  'asOfDate': '2026-07-13',
  'assets': [
    {'ledgerId': 1, 'name': 'Cash', 'amount': 900},
    {'ledgerId': 2, 'name': 'Customer A', 'amount': 100},
  ],
  'liabilities': [
    {'ledgerId': 3, 'name': 'Vendor B', 'amount': 400},
  ],
  'capital': <Map<String, dynamic>>[],
  'retainedEarnings': 600,
  'totalAssets': 1000,
  'totalLiabilitiesAndCapital': 1000,
  'isBalanced': true,
};

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

  group('flattenReport — sections shape', () {
    const def = ReportCatalog.balanceSheet;

    test('tags every line with its section, then appends the totals', () {
      final table = flattenReport(def, _balanceSheetData);

      expect(table.headers, ['Section', 'Ledger', 'Amount']);
      // Values stay raw — 900, not '900'. That is what lets the Excel export
      // write a cell the user can sum.
      expect(table.rows.take(3), [
        ['Assets', 'Cash', 900],
        ['Assets', 'Customer A', 100],
        ['Liabilities', 'Vendor B', 400],
      ]);
      // Capital is empty, so it contributes no rows — the rest is the totals.
      expect(table.rows.skip(3).every((r) => r.first == 'Totals'), isTrue);
      expect(table.rows.skip(3), hasLength(def.columns.length));
      expect(table.rows, contains(equals(['Totals', 'Total assets', 1000])));
      expect(table.rows, contains(equals(['Totals', 'Balanced', true])));
    });

    test('every row is header-width, so the columns stay aligned', () {
      final table = flattenReport(def, _balanceSheetData);
      for (final row in table.rows) {
        expect(row, hasLength(table.headers.length));
      }
    });

    test('an empty payload yields totals rows but no lines', () {
      final table = flattenReport(def, const <String, dynamic>{});
      expect(table.rows.every((r) => r.first == 'Totals'), isTrue);
    });
  });

  group('flattenReport — table shape', () {
    test('reads the rows out from under rowsPath', () {
      const def = ReportCatalog.salesRegister;
      final table = flattenReport(def, {
        'items': [
          {'voucher_no': 'A1'},
        ],
        'meta': {'total': 1},
      });
      expect(table.headers, def.columns.map((c) => c.label));
      expect(table.rows, hasLength(1));
    });
  });

  group('ReportDefinition.paginated', () {
    test('a table report with a rowsPath pages, a statement does not', () {
      // Drives whether the export re-fetches at export size — get this wrong
      // and the register exports page one.
      expect(ReportCatalog.salesRegister.paginated, isTrue);
      expect(ReportCatalog.balanceSheet.paginated, isFalse);
    });
  });
}
