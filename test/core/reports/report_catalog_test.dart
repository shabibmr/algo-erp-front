import 'package:algo_erp_front/core/reports/report_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportCatalog', () {
    test('live catalog has 44 runnable reports', () {
      expect(ReportCatalog.all.length, 44);
      expect(ReportCatalog.all.every((r) => r.enabled), isTrue);
    });

    test('unavailable catalog holds the four dead backend reports', () {
      expect(ReportCatalog.unavailable.length, 4);
      expect(ReportCatalog.unavailable.every((r) => !r.enabled), isTrue);
      expect(ReportCatalog.unavailable.map((r) => r.id).toSet(), {
        'attendance-summary-report',
        'salary-revision-history',
        'inactive-customer-analysis',
        'leave-balance-register',
      });
    });

    test('phantom cash-flow id is not in the catalog', () {
      expect(ReportCatalog.byId('cash-flow'), isNull);
      final real = ReportCatalog.byId('cash-flow-statement');
      expect(real, isNotNull);
      expect(real!.enabled, isTrue);
      expect(real.endpoint, '/reports/cash-flow-statement');
    });

    test('all live report definitions have unique IDs', () {
      final ids = ReportCatalog.all.map((r) => r.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });

    test('all live report definitions have non-empty required fields', () {
      for (final report in ReportCatalog.all) {
        expect(report.id, isNotEmpty);
        expect(report.title, isNotEmpty);
        expect(report.endpoint, isNotEmpty);
        expect(report.columns, isNotEmpty);
      }
    });

    test('byId resolves each live report by ID', () {
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
        'vendor-leadtime-compliance',
        'ppv-audit',
        'bom-production-costing',
        'bin-location-stock',
        'dead-stock-analysis',
        'statutory-payroll-compliance',
      ];

      expect(expectedIds.length, ReportCatalog.all.length);

      for (final id in expectedIds) {
        final found = ReportCatalog.byId(id);
        expect(found, isNotNull, reason: 'Report with ID $id should exist');
        expect(found?.id, id);
        expect(found?.enabled, isTrue);
      }
    });

    test('byId still resolves unavailable reports for deep links', () {
      for (final r in ReportCatalog.unavailable) {
        final found = ReportCatalog.byId(r.id);
        expect(found, isNotNull);
        expect(found!.enabled, isFalse);
        expect(found.unavailableReason, isNotNull);
        expect(found.unavailableReason, isNotEmpty);
      }
    });

    test('returns null for invalid report ID', () {
      expect(ReportCatalog.byId('invalid-id'), isNull);
    });

    test('live analytics reports have correct endpoints and modules', () {
      final bom = ReportCatalog.byId('bom-production-costing')!;
      expect(bom.endpoint, '/reports/bom-production-costing');
      expect(bom.requiredModule, 'Inventory');

      final commission = ReportCatalog.byId('salesperson-commission')!;
      expect(commission.endpoint, '/reports/salesperson-commission');
      expect(commission.requiredModule, 'Transactions');

      final fa = ReportCatalog.byId('fixed-assets-depreciation')!;
      expect(fa.endpoint, '/reports/fixed-assets-depreciation');
      expect(fa.requiredModule, 'JournalLedger');
    });
  });
}
