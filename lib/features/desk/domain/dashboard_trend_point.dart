import 'package:equatable/equatable.dart';

/// One monthly bucket from `GET /reports/dashboard/trend`.
class DashboardTrendPoint extends Equatable {
  const DashboardTrendPoint({
    required this.month,
    required this.salesCount,
    required this.purchaseCount,
    required this.cashPosition,
    required this.bankPosition,
  });

  factory DashboardTrendPoint.fromJson(Map<String, dynamic> json) {
    return DashboardTrendPoint(
      month: json['month']?.toString() ?? '',
      salesCount: _asInt(json['sales_count']),
      purchaseCount: _asInt(json['purchase_count']),
      cashPosition: _asNum(json['cash_position']),
      bankPosition: _asNum(json['bank_position']),
    );
  }

  /// `YYYY-MM`, oldest first.
  final String month;
  final int salesCount;
  final int purchaseCount;
  final num cashPosition;
  final num bankPosition;

  @override
  List<Object?> get props => [
    month,
    salesCount,
    purchaseCount,
    cashPosition,
    bankPosition,
  ];
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
