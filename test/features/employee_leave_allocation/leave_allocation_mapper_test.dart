import 'package:algo_erp_front/features/employee_leave_allocation/data/leave_allocation_dto.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/data/leave_allocation_mapper.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/domain/leave_allocation.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = LeaveAllocationMapper();

  test('fromJson reads allocation + included policy', () {
    final dto = LeaveAllocationDto.fromJson({
      'id': 3,
      'employee_id': 7,
      'leave_policy_id': 2,
      'year': 2026,
      'allocated_days': '30.0',
      'carried_forward': '2.5',
      'used_days': '5',
      'leave_policy': {'display_name': 'Annual leave', 'leave_type': 'Annual'},
    });

    final entity = mapper.toEntity(dto);
    expect(entity.employeeId, 7);
    expect(entity.policyName, 'Annual leave');
    expect(entity.policyLeaveType, 'Annual');
    expect(entity.allocatedDays, Decimal.parse('30.0'));
    expect(entity.remaining, Decimal.parse('27.5'));
  });

  test('toCreateJson includes employee_id (BE-009)', () {
    final entity = LeaveAllocation(
      id: 0,
      employeeId: 12,
      leavePolicyId: 4,
      year: 2026,
      allocatedDays: Decimal.fromInt(15),
      carriedForward: Decimal.zero,
      usedDays: Decimal.zero,
    );
    final json = mapper.toDto(entity).toCreateJson();
    expect(json, {
      'employee_id': 12,
      'leave_policy_id': 4,
      'year': 2026,
      'allocated_days': 15.0,
      'carried_forward': 0.0,
    });
  });
}
