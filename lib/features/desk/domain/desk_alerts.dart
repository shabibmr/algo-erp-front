import 'package:equatable/equatable.dart';

/// Action queue from `GET /reports/alerts`.
class DeskAlerts extends Equatable {
  const DeskAlerts({
    required this.expiringDocuments,
    required this.overdueBills,
  });

  factory DeskAlerts.fromJson(Map<String, dynamic> json) {
    final docs = json['expiring_documents'];
    final bills = json['overdue_bills'];
    return DeskAlerts(
      expiringDocuments: docs is List
          ? docs
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (e) => ExpiringDocumentAlert.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : const [],
      overdueBills: bills is List
          ? bills
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (e) =>
                      OverdueBillAlert.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false)
          : const [],
    );
  }

  final List<ExpiringDocumentAlert> expiringDocuments;
  final List<OverdueBillAlert> overdueBills;

  bool get isEmpty => expiringDocuments.isEmpty && overdueBills.isEmpty;

  int get totalCount => expiringDocuments.length + overdueBills.length;

  @override
  List<Object?> get props => [expiringDocuments, overdueBills];
}

class ExpiringDocumentAlert extends Equatable {
  const ExpiringDocumentAlert({
    required this.docType,
    required this.employeeName,
    required this.employeeCode,
    required this.expiryDate,
    required this.daysUntilExpiry,
  });

  factory ExpiringDocumentAlert.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'];
    final empMap = employee is Map<dynamic, dynamic>
        ? Map<String, dynamic>.from(employee)
        : null;
    return ExpiringDocumentAlert(
      docType: json['doc_type']?.toString() ?? 'Document',
      employeeName: empMap?['Name']?.toString() ?? 'Employee',
      employeeCode: empMap?['employee_code']?.toString() ?? '',
      expiryDate: DateTime.tryParse(json['expiry_date']?.toString() ?? ''),
      daysUntilExpiry: _asInt(json['days_until_expiry']),
    );
  }

  final String docType;
  final String employeeName;
  final String employeeCode;
  final DateTime? expiryDate;
  final int? daysUntilExpiry;

  @override
  List<Object?> get props => [
    docType,
    employeeName,
    employeeCode,
    expiryDate,
    daysUntilExpiry,
  ];
}

class OverdueBillAlert extends Equatable {
  const OverdueBillAlert({
    required this.ledgerId,
    required this.refNo,
    required this.voucherNo,
    required this.dueDate,
    required this.amount,
  });

  factory OverdueBillAlert.fromJson(Map<String, dynamic> json) {
    return OverdueBillAlert(
      ledgerId: _asInt(json['ledger_id']) ?? 0,
      refNo: json['ref_no']?.toString() ?? '',
      voucherNo: json['voucher_no']?.toString() ?? '',
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? ''),
      amount: _asNum(json['amount']),
    );
  }

  final int ledgerId;
  final String refNo;
  final String voucherNo;
  final DateTime? dueDate;
  final num amount;

  @override
  List<Object?> get props => [ledgerId, refNo, voucherNo, dueDate, amount];
}

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

num _asNum(Object? v) {
  if (v is num) return v;
  return num.tryParse(v?.toString() ?? '') ?? 0;
}
