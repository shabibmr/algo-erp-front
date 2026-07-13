import 'package:equatable/equatable.dart';

/// Period KPI snapshot from `GET /reports/dashboard`.
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.startDate,
    required this.endDate,
    required this.salesCount,
    required this.purchaseCount,
    required this.cashPosition,
    required this.bankPosition,
    required this.topCustomers,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>? ?? const {};
    final top = json['top_customers'];
    return DashboardSummary(
      startDate: _asDate(period['start_date']),
      endDate: _asDate(period['end_date']),
      salesCount: _asInt(json['sales_count']),
      purchaseCount: _asInt(json['purchase_count']),
      cashPosition: _asNum(json['cash_position']),
      bankPosition: _asNum(json['bank_position']),
      topCustomers: top is List
          ? top
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (e) => TopCustomerRow(
                    voucherLedgerId: _asInt(e['voucher_ledger_id']),
                    count: _asInt(
                      e['_count'] is Map<dynamic, dynamic>
                          ? (e['_count'] as Map<dynamic, dynamic>)['id']
                          : e['count'],
                    ),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  final DateTime? startDate;
  final DateTime? endDate;
  final int salesCount;
  final int purchaseCount;
  final num cashPosition;
  final num bankPosition;
  final List<TopCustomerRow> topCustomers;

  @override
  List<Object?> get props => [
    startDate,
    endDate,
    salesCount,
    purchaseCount,
    cashPosition,
    bankPosition,
    topCustomers,
  ];
}

class TopCustomerRow extends Equatable {
  const TopCustomerRow({required this.voucherLedgerId, required this.count});

  final int voucherLedgerId;
  final int count;

  @override
  List<Object?> get props => [voucherLedgerId, count];
}

DateTime? _asDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

num _asNum(Object? v) {
  if (v is num) return v;
  return num.tryParse(v?.toString() ?? '') ?? 0;
}
