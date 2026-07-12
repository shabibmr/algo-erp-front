import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/features/organization_audit/data/audit_log_dto.dart';
import 'package:algo_erp_front/features/organization_audit/data/audit_log_mapper.dart';
import 'package:algo_erp_front/features/organization_audit/domain/audit_log.dart';
import 'package:fpdart/fpdart.dart';

/// Read-only list of audit events.
class AuditLogRepository implements Repository<AuditLog, int> {
  AuditLogRepository(this._client, {AuditLogMapper? mapper})
    : _mapper = mapper ?? const AuditLogMapper();

  final DioClient _client;
  final AuditLogMapper _mapper;

  static const _path = '/organization/audit-logs';

  @override
  Future<Result<Paginated<AuditLog>>> list(PageQuery query) {
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
        throw const FormatException('Expected audit log list');
      }
      return Paginated<AuditLog>(
        items: [
          for (final raw in items)
            if (raw is Map<String, dynamic>)
              _mapper.toEntity(AuditLogDto.fromJson(raw)),
        ],
        meta: meta,
      );
    });
  }

  @override
  Future<Result<AuditLog>> getById(int id) {
    return Future.value(
      const Left(Failure.unknown('Audit logs are list-only')),
    );
  }

  @override
  Future<Result<AuditLog>> create(AuditLog entity) {
    return Future.value(
      const Left(Failure.unknown('Audit logs are read-only')),
    );
  }

  @override
  Future<Result<AuditLog>> update(int id, AuditLog entity) {
    return Future.value(
      const Left(Failure.unknown('Audit logs are read-only')),
    );
  }

  @override
  Future<Result<Unit>> delete(int id) {
    return Future.value(
      const Left(Failure.unknown('Audit logs are read-only')),
    );
  }
}
