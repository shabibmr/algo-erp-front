import 'package:equatable/equatable.dart';

class LeaveRequestDto extends Equatable {
  const LeaveRequestDto({
    required this.id,
    required this.employeeId,
    required this.leavePolicyId,
    required this.fromDate,
    required this.toDate,
    required this.numberOfDays,
    this.reason,
    this.status = 'Pending',
    this.rejectionReason,
    this.employeeName,
    this.policyName,
  });

  factory LeaveRequestDto.fromJson(Map<String, dynamic> json) {
    final emp = json['employee_details'];
    final pol = json['leave_policy'];
    String? empName;
    if (emp is Map<String, dynamic>) {
      empName = emp['Name'] as String?;
    }
    String? polName;
    if (pol is Map<String, dynamic>) {
      polName = pol['display_name'] as String?;
    }

    return LeaveRequestDto(
      id: json['id'] as int,
      employeeId: json['employee_id'] as int,
      leavePolicyId: json['leave_policy_id'] as int,
      fromDate: _parseDate(json['from_date']) ?? DateTime.now(),
      toDate: _parseDate(json['to_date']) ?? DateTime.now(),
      numberOfDays: json['number_of_days']?.toString() ?? '1',
      reason: json['reason'] as String?,
      status: _statusOf(json['status']),
      rejectionReason: json['rejection_reason'] as String?,
      employeeName: empName,
      policyName: polName,
    );
  }

  final int id;
  final int employeeId;
  final int leavePolicyId;
  final DateTime fromDate;
  final DateTime toDate;
  final String numberOfDays;
  final String? reason;
  final String status;
  final String? rejectionReason;
  final String? employeeName;
  final String? policyName;

  /// Body for create (nested under employee path — no employee_id).
  Map<String, dynamic> toCreateJson() => {
    'leave_policy_id': leavePolicyId,
    'from_date': _dateOnly(fromDate),
    'to_date': _dateOnly(toDate),
    'number_of_days': double.tryParse(numberOfDays) ?? 1,
    'reason': reason,
    'status': 'Pending',
  };

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String _statusOf(Object? raw) {
    if (raw == null) return 'Pending';
    final s = raw.toString();
    // Prisma enum may arrive as PENDING or Pending.
    switch (s.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return s;
    }
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    leavePolicyId,
    fromDate,
    toDate,
    numberOfDays,
    reason,
    status,
    rejectionReason,
    employeeName,
    policyName,
  ];
}
