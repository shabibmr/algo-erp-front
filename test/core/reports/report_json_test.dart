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

  group('flattenReportSections', () {
    const def = ReportCatalog.balanceSheet;

    test('tags every line with its section, then appends the totals', () {
      final table = flattenReportSections(
        data: _balanceSheetData,
        sections: def.sections,
        totals: def.columns,
      );

      expect(table.headers, ['Section', 'Ledger', 'Amount']);
      expect(table.rows.take(3), [
        ['Assets', 'Cash', '900'],
        ['Assets', 'Customer A', '100'],
        ['Liabilities', 'Vendor B', '400'],
      ]);
      // Capital is empty, so it contributes no rows — the rest is the totals.
      expect(table.rows.skip(3).every((r) => r.first == 'Totals'), isTrue);
      expect(table.rows.skip(3), hasLength(def.columns.length));
      expect(table.rows, contains(equals(['Totals', 'Total assets', '1000'])));
      expect(table.rows, contains(equals(['Totals', 'Balanced', 'Yes'])));
    });

    test('every row is header-width, so CSV columns stay aligned', () {
      final table = flattenReportSections(
        data: _balanceSheetData,
        sections: def.sections,
        totals: def.columns,
      );
      for (final row in table.rows) {
        expect(row, hasLength(table.headers.length));
      }
    });

    test('an empty payload yields totals rows but no lines', () {
      final table = flattenReportSections(
        data: const <String, dynamic>{},
        sections: def.sections,
        totals: def.columns,
      );
      expect(table.rows.every((r) => r.first == 'Totals'), isTrue);
    });

    test('no sections yields no rows rather than throwing', () {
      final table = flattenReportSections(
        data: _balanceSheetData,
        sections: const [],
        totals: def.columns,
      );
      expect(table.rows, isEmpty);
    });
  });
}
