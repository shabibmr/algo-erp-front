import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// Leave request with approval workflow status.
class LeaveRequest extends Equatable {
  const LeaveRequest({
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

  static const statuses = ['Pending', 'Approved', 'Rejected', 'Cancelled'];

  final int id;
  final int employeeId;
  final int leavePolicyId;
  final DateTime fromDate;
  final DateTime toDate;
  final Decimal numberOfDays;
  final String? reason;
  final String status;
  final String? rejectionReason;

  /// Display helpers from list include.
  final String? employeeName;
  final String? policyName;

  LeaveRequest copyWith({
    int? id,
    int? employeeId,
    int? leavePolicyId,
    DateTime? fromDate,
    DateTime? toDate,
    Decimal? numberOfDays,
    Object? reason = _unset,
    String? status,
    Object? rejectionReason = _unset,
    Object? employeeName = _unset,
    Object? policyName = _unset,
  }) => LeaveRequest(
    id: id ?? this.id,
    employeeId: employeeId ?? this.employeeId,
    leavePolicyId: leavePolicyId ?? this.leavePolicyId,
    fromDate: fromDate ?? this.fromDate,
    toDate: toDate ?? this.toDate,
    numberOfDays: numberOfDays ?? this.numberOfDays,
    reason: identical(reason, _unset) ? this.reason : reason as String?,
    status: status ?? this.status,
    rejectionReason: identical(rejectionReason, _unset)
        ? this.rejectionReason
        : rejectionReason as String?,
    employeeName: identical(employeeName, _unset)
        ? this.employeeName
        : employeeName as String?,
    policyName: identical(policyName, _unset)
        ? this.policyName
        : policyName as String?,
  );

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
