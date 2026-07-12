import 'package:algo_erp_front/features/employee_leave_policy/data/leave_policy_dto.dart';
import 'package:algo_erp_front/features/employee_leave_policy/data/leave_policy_mapper.dart';
import 'package:algo_erp_front/features/employee_leave_policy/domain/leave_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = LeavePolicyMapper();

  test('fromJson reads leave policy wire keys', () {
    final dto = LeavePolicyDto.fromJson(const {
      'id': 1,
      'leave_type': 'Annual',
      'display_name': 'Annual leave',
      'max_days_per_year': 30,
      'is_paid': true,
      'is_active': true,
    });
    expect(dto.leaveType, 'Annual');
    expect(dto.maxDaysPerYear, 30);
  });

  test('toJson omits id and matches create body', () {
    const policy = LeavePolicy(
      id: 9,
      leaveType: 'Sick',
      displayName: 'Sick leave',
      maxDaysPerYear: 15,
      isPaid: true,
    );
    expect(mapper.toDto(policy).toJson(), {
      'leave_type': 'Sick',
      'display_name': 'Sick leave',
      'max_days_per_year': 15,
      'max_days_per_request': null,
      'carry_forward_limit': 0,
      'requires_approval': true,
      'is_paid': true,
      'applicable_gender': null,
      'is_active': true,
    });
  });
}
