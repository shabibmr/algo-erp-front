import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/data/leave_allocation_repository.dart';

LeaveAllocationRepository createLeaveAllocationRepository(DioClient client) {
  return LeaveAllocationRepository(client);
}
