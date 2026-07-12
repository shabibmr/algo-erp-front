import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/employee_leave_policy/data/leave_policy_dto.dart';
import 'package:algo_erp_front/features/employee_leave_policy/domain/leave_policy.dart';

class LeavePolicyMapper implements Mapper<LeavePolicyDto, LeavePolicy> {
  const LeavePolicyMapper();

  @override
  LeavePolicy toEntity(LeavePolicyDto dto) => LeavePolicy(
    id: dto.id,
    leaveType: dto.leaveType,
    displayName: dto.displayName,
    maxDaysPerYear: dto.maxDaysPerYear,
    maxDaysPerRequest: dto.maxDaysPerRequest,
    carryForwardLimit: dto.carryForwardLimit,
    requiresApproval: dto.requiresApproval,
    isPaid: dto.isPaid,
    applicableGender: dto.applicableGender,
    isActive: dto.isActive,
  );

  @override
  LeavePolicyDto toDto(LeavePolicy entity) => LeavePolicyDto(
    id: entity.id,
    leaveType: entity.leaveType,
    displayName: entity.displayName,
    maxDaysPerYear: entity.maxDaysPerYear,
    maxDaysPerRequest: entity.maxDaysPerRequest,
    carryForwardLimit: entity.carryForwardLimit,
    requiresApproval: entity.requiresApproval,
    isPaid: entity.isPaid,
    applicableGender: entity.applicableGender,
    isActive: entity.isActive,
  );
}
