import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/data/leave_allocation_dto.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/data/leave_allocation_mapper.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/domain/leave_allocation.dart';
import 'package:fpdart/fpdart.dart';

/// Leave allocations: create global POST; list is per-employee only.
class LeaveAllocationRepository implements Repository<LeaveAllocation, int> {
  LeaveAllocationRepository(this._client, {LeaveAllocationMapper? mapper})
    : _mapper = mapper ?? const LeaveAllocationMapper();

  final DioClient _client;
  final LeaveAllocationMapper _mapper;

  static const _createPath = '/employee/leave/allocations';

  /// List for one employee + calendar year.
  Future<Result<List<LeaveAllocation>>> listForEmployee({
    required int employeeId,
    required int year,
  }) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        '/employee/employees/$employeeId/leave-allocations',
        queryParameters: {'year': year},
      );
      final envelope = decodeApiResponse<Object?>(res.data, (j) => j);
      final data = envelope.data;
      final items = _extractItems(data);
      return [
        for (final raw in items)
          if (raw is Map<String, dynamic>)
            _mapper.toEntity(LeaveAllocationDto.fromJson(raw)),
      ];
    });
  }

  List<dynamic> _extractItems(Object? data) {
    if (data is Map<String, dynamic> && data['items'] is List) {
      return data['items'] as List<dynamic>;
    }
    if (data is List) return data;
    throw const FormatException('Expected leave allocation list');
  }

  @override
  Future<Result<Paginated<LeaveAllocation>>> list(PageQuery query) {
    // No global list endpoint — UI must call [listForEmployee].
    return Future.value(
      Right(
        Paginated<LeaveAllocation>(
          items: const [],
          meta: PaginationMeta(
            total: 0,
            page: query.page,
            limit: query.limit,
            totalPages: 0,
          ),
        ),
      ),
    );
  }

  @override
  Future<Result<LeaveAllocation>> getById(int id) {
    return Future.value(
      const Left(Failure.unknown('Leave allocations have no get-by-id route')),
    );
  }

  @override
  Future<Result<LeaveAllocation>> create(LeaveAllocation entity) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        _createPath,
        data: _mapper.toDto(entity).toCreateJson(),
      );
      final envelope = decodeApiResponse<Map<String, dynamic>>(
        res.data,
        (j) => j! as Map<String, dynamic>,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected leave allocation in response');
      }
      return _mapper.toEntity(LeaveAllocationDto.fromJson(data));
    });
  }

  @override
  Future<Result<LeaveAllocation>> update(int id, LeaveAllocation entity) {
    return Future.value(
      const Left(Failure.unknown('Leave allocations cannot be updated')),
    );
  }

  @override
  Future<Result<Unit>> delete(int id) {
    return Future.value(
      const Left(Failure.unknown('Leave allocations cannot be deleted')),
    );
  }
}
