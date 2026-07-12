import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/features/employee_leave_request/data/leave_request_dto.dart';
import 'package:algo_erp_front/features/employee_leave_request/data/leave_request_mapper.dart';
import 'package:algo_erp_front/features/employee_leave_request/domain/leave_request.dart';
import 'package:fpdart/fpdart.dart';

/// Leave requests: list global, create nested under employee, status via PUT.
class LeaveRequestRepository implements Repository<LeaveRequest, int> {
  LeaveRequestRepository(this._client, {LeaveRequestMapper? mapper})
    : _mapper = mapper ?? const LeaveRequestMapper();

  final DioClient _client;
  final LeaveRequestMapper _mapper;

  static const _listPath = '/employee/leave-requests';

  @override
  Future<Result<Paginated<LeaveRequest>>> list(PageQuery query) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        _listPath,
        queryParameters: {
          'page': query.page,
          'limit': query.limit,
          if (query.search != null && query.search!.isNotEmpty)
            'search': query.search,
        },
      );
      final envelope = decodeApiResponse<Object?>(res.data, (j) => j);
      final data = envelope.data;
      List<dynamic> items;
      PaginationMeta meta;
      if (data is Map<String, dynamic> && data['items'] is List) {
        items = data['items'] as List<dynamic>;
        final m = data['meta'] as Map<String, dynamic>?;
        meta = PaginationMeta(
          total: m?['total'] as int? ?? items.length,
          page: m?['page'] as int? ?? query.page,
          limit: m?['limit'] as int? ?? query.limit,
          totalPages: m?['totalPages'] as int? ?? 1,
        );
      } else if (data is List) {
        items = data;
        meta = PaginationMeta(
          total: items.length,
          page: 1,
          limit: items.length,
          totalPages: 1,
        );
      } else {
        throw const FormatException('Expected leave request list');
      }
      return Paginated<LeaveRequest>(
        items: [
          for (final raw in items)
            if (raw is Map<String, dynamic>)
              _mapper.toEntity(LeaveRequestDto.fromJson(raw)),
        ],
        meta: meta,
      );
    });
  }

  @override
  Future<Result<LeaveRequest>> getById(int id) async {
    final listed = await list(const PageQuery(limit: 200));
    return listed.fold(Left.new, (page) {
      for (final r in page.items) {
        if (r.id == id) return Right(r);
      }
      return const Left(Failure.notFound('Leave request not found'));
    });
  }

  @override
  Future<Result<LeaveRequest>> create(LeaveRequest entity) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        '/employee/employees/${entity.employeeId}/leave-requests',
        data: _mapper.toDto(entity).toCreateJson(),
      );
      final envelope = decodeApiResponse<Map<String, dynamic>>(
        res.data,
        (j) => j! as Map<String, dynamic>,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected leave request in response');
      }
      return _mapper.toEntity(LeaveRequestDto.fromJson(data));
    });
  }

  @override
  Future<Result<LeaveRequest>> update(int id, LeaveRequest entity) {
    return updateStatus(id, entity.status, reason: entity.rejectionReason);
  }

  Future<Result<LeaveRequest>> updateStatus(
    int id,
    String status, {
    String? reason,
  }) {
    return safeCall(() async {
      final res = await _client.dio.put<Object?>(
        '/employee/leave-requests/$id',
        data: {
          'status': status,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      final envelope = decodeApiResponse<Map<String, dynamic>>(
        res.data,
        (j) => j! as Map<String, dynamic>,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected leave request in response');
      }
      return _mapper.toEntity(LeaveRequestDto.fromJson(data));
    });
  }

  @override
  Future<Result<Unit>> delete(int id) {
    return Future.value(
      const Left(
        Failure.unknown('Leave requests use cancel status, not delete'),
      ),
    );
  }
}
