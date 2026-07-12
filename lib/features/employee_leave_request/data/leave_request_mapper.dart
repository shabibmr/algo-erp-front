import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/employee_leave_request/data/leave_request_dto.dart';
import 'package:algo_erp_front/features/employee_leave_request/domain/leave_request.dart';
import 'package:decimal/decimal.dart';

class LeaveRequestMapper implements Mapper<LeaveRequestDto, LeaveRequest> {
  const LeaveRequestMapper();

  @override
  LeaveRequest toEntity(LeaveRequestDto dto) => LeaveRequest(
    id: dto.id,
    employeeId: dto.employeeId,
    leavePolicyId: dto.leavePolicyId,
    fromDate: dto.fromDate,
    toDate: dto.toDate,
    numberOfDays: Decimal.tryParse(dto.numberOfDays) ?? Decimal.one,
    reason: dto.reason,
    status: dto.status,
    rejectionReason: dto.rejectionReason,
    employeeName: dto.employeeName,
    policyName: dto.policyName,
  );

  @override
  LeaveRequestDto toDto(LeaveRequest entity) => LeaveRequestDto(
    id: entity.id,
    employeeId: entity.employeeId,
    leavePolicyId: entity.leavePolicyId,
    fromDate: entity.fromDate,
    toDate: entity.toDate,
    numberOfDays: entity.numberOfDays.toString(),
    reason: entity.reason,
    status: entity.status,
    rejectionReason: entity.rejectionReason,
    employeeName: entity.employeeName,
    policyName: entity.policyName,
  );
}
