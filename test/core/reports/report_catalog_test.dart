import 'package:algo_erp_front/core/reports/report_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportCatalog', () {
    test('contains 49 stamped report definitions', () {
      expect(ReportCatalog.all.length, 49);
    });

    test('all report definitions have unique IDs', () {
      final ids = ReportCatalog.all.map((r) => r.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });

    test('all report definitions have non-empty required fields', () {
      for (final report in ReportCatalog.all) {
        expect(report.id, isNotEmpty);
        expect(report.title, isNotEmpty);
        expect(report.endpoint, isNotEmpty);
        expect(report.columns, isNotEmpty);
      }
    });

    test('byId resolves each defined report by ID', () {
      final expectedIds = [
        'sales-register',
        'purchase-register',
        'stock-summary',
        'stock-valuation',
        'vat-return',
        'trial-balance',
        'day-book',
        'profit-loss',
        'balance-sheet',
        'ledger-statement',
        'accounts-aging',
        'overtime-summary',
        'credit-note-register',
        'debit-note-register',
        'quotation-register',
        'sales-order-register',
        'purchase-order-register',
        'delivery-note-register',
        'receipt-note-register',
        'godown-transfer-register',
        'receipts-summary',
        'payments-summary',
        'material-requirements',
        'item-batches-report',
        'payroll-register',
        'attendance-summary-report',
        'salary-revision-history',
        'cash-flow',
        'budget-variance',
        'collection-efficiency',
        'ap-forecast',
        'vendor-expenses',
        'sales-analytics',
        'sales-margin',
        'price-variance',
        'stock-movement',
        'bank-reconciliation',
        'cash-flow-statement',
        'fixed-assets-depreciation',
        'quotation-conversion-ratio',
        'salesperson-commission',
        'inactive-customer-analysis',
        'vendor-leadtime-compliance',
        'ppv-audit',
        'bom-production-costing',
        'bin-location-stock',
        'dead-stock-analysis',
        'statutory-payroll-compliance',
        'leave-balance-register',
      ];

      for (final id in expectedIds) {
        final found = ReportCatalog.byId(id);
        expect(found, isNotNull, reason: 'Report with ID $id should exist');
        expect(found?.id, id);
      }
    });

    test('returns null for invalid report ID', () {
      expect(ReportCatalog.byId('invalid-id'), isNull);
    });

    test('newly added reports have correct endpoints and parameters', () {
      final bom = ReportCatalog.byId('bom-production-costing')!;
      expect(bom.endpoint, '/reports/bom-production-costing');
      expect(bom.requiredModule, 'Inventory');

      final commission = ReportCatalog.byId('salesperson-commission')!;
      expect(commission.endpoint, '/reports/salesperson-commission');
      expect(commission.requiredModule, 'Transactions');

      final leave = ReportCatalog.byId('leave-balance-register')!;
      expect(leave.endpoint, '/reports/leave-balance-register');
      expect(leave.requiredModule, 'Employee');

      final fa = ReportCatalog.byId('fixed-assets-depreciation')!;
      expect(fa.endpoint, '/reports/fixed-assets-depreciation');
      expect(fa.requiredModule, 'JournalLedger');
    });
  });
}
