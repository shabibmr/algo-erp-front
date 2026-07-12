import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/features/employee_leave_policy/data/leave_policy_dto.dart';
import 'package:algo_erp_front/features/employee_leave_policy/data/leave_policy_mapper.dart';
import 'package:algo_erp_front/features/employee_leave_policy/domain/leave_policy.dart';
import 'package:fpdart/fpdart.dart';

/// Leave policies: `GET/POST /employee/leave/policies` only.
///
/// [getById] scans the list (no backend get-by-id). Update/delete refuse.
class LeavePolicyRepository implements Repository<LeavePolicy, int> {
  LeavePolicyRepository(this._client, {LeavePolicyMapper? mapper})
    : _mapper = mapper ?? const LeavePolicyMapper();

  final DioClient _client;
  final LeavePolicyMapper _mapper;

  static const _path = '/employee/leave/policies';

  @override
  Future<Result<Paginated<LeavePolicy>>> list(PageQuery query) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        _path,
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
        throw const FormatException('Expected leave policy list');
      }
      return Paginated<LeavePolicy>(
        items: [
          for (final raw in items)
            if (raw is Map<String, dynamic>)
              _mapper.toEntity(LeavePolicyDto.fromJson(raw)),
        ],
        meta: meta,
      );
    });
  }

  @override
  Future<Result<LeavePolicy>> getById(int id) async {
    final listed = await list(const PageQuery(limit: 200));
    return listed.fold(Left.new, (page) {
      for (final p in page.items) {
        if (p.id == id) return Right(p);
      }
      return const Left(Failure.notFound('Leave policy not found'));
    });
  }

  @override
  Future<Result<LeavePolicy>> create(LeavePolicy entity) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        _path,
        data: _mapper.toDto(entity).toJson(),
      );
      final envelope = decodeApiResponse<Map<String, dynamic>>(
        res.data,
        (j) => j! as Map<String, dynamic>,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected leave policy in response');
      }
      return _mapper.toEntity(LeavePolicyDto.fromJson(data));
    });
  }

  @override
  Future<Result<LeavePolicy>> update(int id, LeavePolicy entity) {
    return Future.value(
      const Left(Failure.unknown('Leave policies cannot be updated')),
    );
  }

  @override
  Future<Result<Unit>> delete(int id) {
    return Future.value(
      const Left(Failure.unknown('Leave policies cannot be deleted')),
    );
  }
}
