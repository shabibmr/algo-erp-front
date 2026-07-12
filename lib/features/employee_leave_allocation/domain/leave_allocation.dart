import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// Yearly leave balance for one employee + policy.
///
/// Backend: create `POST /employee/leave/allocations`; list only per employee
/// `GET /employee/employees/:id/leave-allocations?year=`.
class LeaveAllocation extends Equatable {
  LeaveAllocation({
    required this.id,
    required this.employeeId,
    required this.leavePolicyId,
    required this.year,
    required this.allocatedDays,
    Decimal? carriedForward,
    Decimal? usedDays,
    this.policyName,
    this.policyLeaveType,
    this.employeeName,
  }) : carriedForward = carriedForward ?? Decimal.zero,
       usedDays = usedDays ?? Decimal.zero;

  final int id;
  final int employeeId;
  final int leavePolicyId;
  final int year;
  final Decimal allocatedDays;
  final Decimal carriedForward;
  final Decimal usedDays;

  /// From list include `leave_policy`.
  final String? policyName;
  final String? policyLeaveType;

  /// Client-only display when known from the filter picker.
  final String? employeeName;

  Decimal get remaining => allocatedDays + carriedForward - usedDays;

  LeaveAllocation copyWith({
    int? id,
    int? employeeId,
    int? leavePolicyId,
    int? year,
    Decimal? allocatedDays,
    Decimal? carriedForward,
    Decimal? usedDays,
    Object? policyName = _unset,
    Object? policyLeaveType = _unset,
    Object? employeeName = _unset,
  }) => LeaveAllocation(
    id: id ?? this.id,
    employeeId: employeeId ?? this.employeeId,
    leavePolicyId: leavePolicyId ?? this.leavePolicyId,
    year: year ?? this.year,
    allocatedDays: allocatedDays ?? this.allocatedDays,
    carriedForward: carriedForward ?? this.carriedForward,
    usedDays: usedDays ?? this.usedDays,
    policyName: identical(policyName, _unset)
        ? this.policyName
        : policyName as String?,
    policyLeaveType: identical(policyLeaveType, _unset)
        ? this.policyLeaveType
        : policyLeaveType as String?,
    employeeName: identical(employeeName, _unset)
        ? this.employeeName
        : employeeName as String?,
  );

  @override
  List<Object?> get props => [
    id,
    employeeId,
    leavePolicyId,
    year,
    allocatedDays,
    carriedForward,
    usedDays,
    policyName,
    policyLeaveType,
    employeeName,
  ];
}
