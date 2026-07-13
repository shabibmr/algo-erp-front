import 'package:algo_erp_front/features/desk/domain/dashboard_summary.dart';
import 'package:algo_erp_front/features/desk/domain/dashboard_trend_point.dart';
import 'package:algo_erp_front/features/desk/domain/desk_alerts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DashboardSummary.fromJson', () {
    final s = DashboardSummary.fromJson(const {
      'period': {
        'start_date': '2026-07-01T00:00:00.000Z',
        'end_date': '2026-07-13T00:00:00.000Z',
      },
      'sales_count': 4,
      'purchase_count': 2,
      'cash_position': 100.5,
      'bank_position': -20,
      'top_customers': [
        {
          'voucher_ledger_id': 9,
          '_count': {'id': 3},
        },
      ],
    });
    expect(s.salesCount, 4);
    expect(s.purchaseCount, 2);
    expect(s.cashPosition, 100.5);
    expect(s.topCustomers.single.voucherLedgerId, 9);
    expect(s.topCustomers.single.count, 3);
  });

  test('DeskAlerts.fromJson', () {
    final a = DeskAlerts.fromJson(const {
      'expiring_documents': [
        {
          'doc_type': 'Passport',
          'expiry_date': '2026-08-01',
          'days_until_expiry': 19,
          'employee': {'Name': 'Ada', 'employee_code': 'E1'},
        },
      ],
      'overdue_bills': [
        {
          'ledger_id': 1,
          'ref_no': 'R1',
          'voucher_no': 'V1',
          'due_date': '2026-06-01',
          'amount': 50,
        },
      ],
    });
    expect(a.totalCount, 2);
    expect(a.expiringDocuments.single.employeeName, 'Ada');
    expect(a.overdueBills.single.voucherNo, 'V1');
  });

  test('DashboardTrendPoint.fromJson', () {
    final p = DashboardTrendPoint.fromJson(const {
      'month': '2026-06',
      'sales_count': 5,
      'purchase_count': 3,
      'cash_position': 120.25,
      'bank_position': -15,
    });
    expect(p.month, '2026-06');
    expect(p.salesCount, 5);
    expect(p.purchaseCount, 3);
    expect(p.cashPosition, 120.25);
    expect(p.bankPosition, -15);
  });
}
