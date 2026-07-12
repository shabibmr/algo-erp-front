import 'package:equatable/equatable.dart';

class LeaveAllocationDto extends Equatable {
  const LeaveAllocationDto({
    required this.id,
    required this.employeeId,
    required this.leavePolicyId,
    required this.year,
    required this.allocatedDays,
    this.carriedForward = '0',
    this.usedDays = '0',
    this.policyName,
    this.policyLeaveType,
  });

  factory LeaveAllocationDto.fromJson(Map<String, dynamic> json) {
    final policy = json['leave_policy'];
    String? policyName;
    String? policyType;
    if (policy is Map<String, dynamic>) {
      policyName = policy['display_name'] as String?;
      policyType = policy['leave_type'] as String?;
    }

    return LeaveAllocationDto(
      id: json['id'] as int? ?? 0,
      employeeId: json['employee_id'] as int,
      leavePolicyId: json['leave_policy_id'] as int,
      year: json['year'] as int,
      allocatedDays: json['allocated_days']?.toString() ?? '0',
      carriedForward: json['carried_forward']?.toString() ?? '0',
      usedDays: json['used_days']?.toString() ?? '0',
      policyName: policyName,
      policyLeaveType: policyType,
    );
  }

  final int id;
  final int employeeId;
  final int leavePolicyId;
  final int year;
  final String allocatedDays;
  final String carriedForward;
  final String usedDays;
  final String? policyName;
  final String? policyLeaveType;

  /// Create body for `POST /employee/leave/allocations` (BE-009).
  Map<String, dynamic> toCreateJson() => {
    'employee_id': employeeId,
    'leave_policy_id': leavePolicyId,
    'year': year,
    'allocated_days': double.tryParse(allocatedDays) ?? 0,
    'carried_forward': double.tryParse(carriedForward) ?? 0,
  };

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
  ];
}
