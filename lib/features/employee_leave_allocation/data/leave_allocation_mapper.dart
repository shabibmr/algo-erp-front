import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/data/leave_allocation_dto.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/domain/leave_allocation.dart';
import 'package:decimal/decimal.dart';

class LeaveAllocationMapper
    implements Mapper<LeaveAllocationDto, LeaveAllocation> {
  const LeaveAllocationMapper();

  @override
  LeaveAllocation toEntity(LeaveAllocationDto dto) => LeaveAllocation(
    id: dto.id,
    employeeId: dto.employeeId,
    leavePolicyId: dto.leavePolicyId,
    year: dto.year,
    allocatedDays: Decimal.tryParse(dto.allocatedDays) ?? Decimal.zero,
    carriedForward: Decimal.tryParse(dto.carriedForward) ?? Decimal.zero,
    usedDays: Decimal.tryParse(dto.usedDays) ?? Decimal.zero,
    policyName: dto.policyName,
    policyLeaveType: dto.policyLeaveType,
  );

  @override
  LeaveAllocationDto toDto(LeaveAllocation entity) => LeaveAllocationDto(
    id: entity.id,
    employeeId: entity.employeeId,
    leavePolicyId: entity.leavePolicyId,
    year: entity.year,
    allocatedDays: entity.allocatedDays.toString(),
    carriedForward: entity.carriedForward.toString(),
    usedDays: entity.usedDays.toString(),
    policyName: entity.policyName,
    policyLeaveType: entity.policyLeaveType,
  );
}
